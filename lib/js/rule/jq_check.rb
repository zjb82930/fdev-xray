# encoding: utf-8

require_relative '../../rule_helper'

module XRay
  module JS
    module Rule
     
      class JqCheck

        include RuleHelper, Helper

        JQ_IDS = %w(jQuery $ jQ jq)
        
        def visit_expr_member(expr)
          dispatch [
            :check_direct_jquery_call,
            :check_forbit_method_call,
            :check_data_call_param,
            :check_ctor_selector
          ], expr
        end

        def check_direct_jquery_call(expr)
          expr = find_expr_member(expr) do |expr| 
            ['.', '(', '['].include?(expr.type) && expr.left.text == 'jQuery'
          end
          
          return unless expr

          unless expr.type == '.' && expr.right.text == 'namespace'
            ['禁止直接使用jQuery变量，使用全局闭包写法"(function($, NS){....})(jQuery,Namespace);"，jQuery.namespace例外', :error]
          end
        end

        def check_forbit_method_call(expr)
          methods = %w(sub noConflict)
          expr = find_expr_member(expr) do |expr|
            expr.type == '.' && JQ_IDS.include?(expr.left.text) && 
              methods.include?(expr.right.text) 
          end

          ['禁止使用jQuery.sub()和jQuery.noConflict方法', :error] if expr
        end

        def check_data_call_param(expr)
          expr = find_expr_member(expr) do |expr| 
            if expr.type == '('
              name = expr.left
              if name.is_a?(Expression) && name.type == '.' && 
                  name.right.text == 'data'
                param = expr.right[0]
                param && param.text =~ /[-_]/
              end
            end  
          end
          
          ['使用".data()"读写自定义属性时需要转化成驼峰形式', :error] if expr
        end

        def check_ctor_selector(expr)
          expr = find_expr_member(expr) do |expr|
            expr.type == '(' && JQ_IDS.include?(expr.left.text)
          end
          
          return unless expr
          
          param = expr.right[0] 
          if param && param.type == 'string' && !good_selector?(param.text)
            ['使用选择器时，能确定tagName的，必须加上tagName', :warn]
          end
        end

        private

        def good_selector?(selector)
          return /^['"][#\w<]/ =~ selector
        end
         
      end
    
    end
  end
end