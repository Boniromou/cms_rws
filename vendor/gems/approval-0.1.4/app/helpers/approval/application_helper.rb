module Approval
  module ApplicationHelper
    def method_missing method, *args, &block
      if method.to_s.end_with?('_path') or method.to_s.end_with?('_url')
        if main_app.respond_to?(method)
          main_app.send(method, *args)
        else
          super
        end
      else
        super
      end
    end

    def respond_to?(method)
      if method.to_s.end_with?('_path') or method.to_s.end_with?('_url')
        if main_app.respond_to?(method)
          true
        else
          super
        end
      else
        super
      end
    end

    def breadcrumbs(titles, icon_class, options={})
      dom_id = options[:id] || "breadcrumbs"
      klass = options[:class] || "col-xs-12 col-sm-12 col-md-12 col-lg-12"

      content_tag :div, :class => "row" do
        content_tag :div, :id => dom_id, :class => klass do
          content_tag :h2, :class => "page-title txt-color-blueDark" do
            concat content_tag(:i, nil, :class => icon_class)

            titles.each_with_index.map do |title, index|
              label = " #{title} "
              separator = '&gt;'.html_safe

              if (index + 1) == titles.length  && index != 0
                span = content_tag :span do
                  concat separator
                  concat label
                end
                concat span
              elsif index != 0
                concat separator
                concat label
              else
                concat label
              end
            end
          end
        end
      end
    end

    def table_tabs(selected, *tabs)
      content_tag :ul, :class => "nav nav-tabs bordered" do
        tabs.each do |tab_info|
          title = tab_info[0]
          path = tab_info[1]
          visible = tab_info[2]
          remote = tab_info[3]
          if visible
            li_div = content_tag(:li, nil, :class => selected == title ? "active" : "" ) do
              concat link_to(title, path, remote: remote)
            end
            
            concat li_div
          end
        end
      end
    end
  end
end
