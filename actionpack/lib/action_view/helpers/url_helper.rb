module ActionView
  module Helpers
    # Provides a set of methods for making easy links and getting urls that depend on the controller and action. This means that
    # you can use the same format for links in the views that you do in the controller. The different methods are even named
    # synchronously, so link_to uses that same url as is generated by url_for, which again is the same url used for
    # redirection in redirect_to.
    module UrlHelper
      # Returns the URL for the set of +options+ provided. This takes the same options 
      # as url_for. For a list, see the url_for documentation in link:classes/ActionController/Base.html#M000079.
      def url_for(options = {}, *parameters_for_method_reference)
        options = { :only_path => true }.update(options.symbolize_keys) if options.kind_of? Hash
        @controller.send(:url_for, options, *parameters_for_method_reference)
      end

      # Creates a link tag of the given +name+ using an URL created by the set of +options+. See the valid options in
      # link:classes/ActionController/Base.html#M000021. It's also possible to pass a string instead of an options hash to
      # get a link tag that just points without consideration. If nil is passed as a name, the link itself will become the name.
      # The html_options have a special feature for creating javascript confirm alerts where if you pass :confirm => 'Are you sure?',
      # the link will be guarded with a JS popup asking that question. If the user accepts, the link is processed, otherwise not.
      #
      # Example:
      #   link_to "Delete this page", { :action => "destroy", :id => @page.id }, :confirm => "Are you sure?"
      def link_to(name, options = {}, html_options = nil, *parameters_for_method_reference)
        html_options = (html_options || {}).stringify_keys
        convert_confirm_option_to_javascript!(html_options)
        if options.is_a?(String)
          content_tag "a", name || options, (html_options || {}).merge("href" => options)
        else
          content_tag(
            "a", name || url_for(options, *parameters_for_method_reference),
            (html_options || {}).merge("href" => url_for(options, *parameters_for_method_reference))
          )
        end
      end

      # Generates a form containing a sole button that submits to the
      # URL given by _options_.  Use this method instead of +link_to+
      # for actions that do not have the safe HTTP GET semantics
      # implied by using a hypertext link.
      #
      # The parameters are the same as for +link_to+.  Any _html_options_
      # that you pass will be applied to the inner +input+ element.
      # In particular, pass
      # 
      #   :disabled => true/false
      #
      # as part of _html_options_ to control whether the button is
      # disabled.  The generated form element is given the class
      # 'button-to', to which you can attach CSS styles for display
      # purposes.
      #
      # Example 1:
      #
      #   # inside of controller for "feeds"
      #   button_to "Edit", :action => 'edit', :id => 3
      #
      # Generates the following HTML (sans formatting):
      #
      #   <form method="post" action="/feeds/edit/3" class="button-to">
      #     <div><input value="Edit" type="submit" /></div>
      #   </form>
      #
      # Example 2:
      #
      #   button_to "Destroy", { :action => 'destroy', :id => 3 },
      #             :confirm => "Are you sure?"
      #
      # Generates the following HTML (sans formatting):
      #
      #   <form method="post" action="/feeds/destroy/3" class="button-to">
      #     <div><input onclick="return confirm('Are you sure?');"
      #                 value="Destroy" type="submit" />
      #     </div>
      #   </form>
      #
      # *NOTE*: This method generates HTML code that represents a form.
      # Forms are "block" content, which means that you should not try to
      # insert them into your HTML where only inline content is expected.
      # For example, you can legally insert a form inside of a +div+ or
      # +td+ element or in between +p+ elements, but not in the middle of
      # a run of text, nor can you place a form within another form.
      # (Bottom line: Always validate your HTML before going public.)

      def button_to(name, options = {}, html_options = nil)
        html_options = (html_options || {}).stringify_keys
        convert_boolean_attributes!(html_options, %w( disabled ))
        convert_confirm_option_to_javascript!(html_options)
        url, name = options.is_a?(String) ? 
          [ options,  name || options ] :
          [ url_for(options), name || url_for(options) ]
        html_options.merge!("type" => "submit", "value" => name)
        "<form method=\"post\" action=\"#{h url}\" class=\"button-to\"><div>" +
          tag("input", html_options) + "</div></form>"
      end


      # This tag is deprecated. Combine the link_to and AssetTagHelper::image_tag yourself instead, like:
      #   link_to(image_tag("rss", :size => "30x45", :border => 0), "http://www.example.com")
      def link_image_to(src, options = {}, html_options = {}, *parameters_for_method_reference)
        image_options = { "src" => src.include?("/") ? src : "/images/#{src}" }
        image_options["src"] += ".png" unless image_options["src"].include?(".")

        html_options = html_options.stringify_keys
        if html_options["alt"]
          image_options["alt"] = html_options["alt"]
          html_options.delete "alt"
        else
          image_options["alt"] = src.split("/").last.split(".").first.capitalize
        end

        if html_options["size"]
          image_options["width"], image_options["height"] = html_options["size"].split("x")
          html_options.delete "size"
        end

        if html_options["border"]
          image_options["border"] = html_options["border"]
          html_options.delete "border"
        end

        if html_options["align"]
          image_options["align"] = html_options["align"]
          html_options.delete "align"
        end

        link_to(tag("img", image_options), options, html_options, *parameters_for_method_reference)
      end

      alias_method :link_to_image, :link_image_to # deprecated name

      # Creates a link tag of the given +name+ using an URL created by the set of +options+, unless the current
      # request uri is the same as the link's, in which case only the name is returned (or the
      # given block is yielded, if one exists). This is useful for creating link bars where you don't want to link
      # to the page currently being viewed.
      def link_to_unless_current(name, options = {}, html_options = {}, *parameters_for_method_reference, &block)
        link_to_unless current_page?(options), name, options, html_options, *parameters_for_method_reference, &block
      end

      # Create a link tag of the given +name+ using an URL created by the set of +options+, unless +condition+
      # is true, in which case only the name is returned (or the given block is yielded, if one exists). 
      def link_to_unless(condition, name, options = {}, html_options = {}, *parameters_for_method_reference, &block)
        if condition
          if block_given?
            block.arity <= 1 ? yield(name) : yield(name, options, html_options, *parameters_for_method_reference)
          else
            html_escape(name)
          end
        else
          link_to(name, options, html_options, *parameters_for_method_reference)
        end  
      end
      
      # Create a link tag of the given +name+ using an URL created by the set of +options+, if +condition+
      # is true, in which case only the name is returned (or the given block is yielded, if one exists). 
      def link_to_if(condition, name, options = {}, html_options = {}, *parameters_for_method_reference, &block)
        link_to_unless !condition, name, options, html_options, *parameters_for_method_reference, &block
      end

      # Creates a link tag for starting an email to the specified <tt>email_address</tt>, which is also used as the name of the
      # link unless +name+ is specified. Additional HTML options, such as class or id, can be passed in the <tt>html_options</tt> hash.
      #
      # You can also make it difficult for spiders to harvest email address by obfuscating them.
      # Examples:
      #   mail_to "me@domain.com", "My email", :encode => "javascript"  # =>
      #     <script type="text/javascript" language="javascript">eval(unescape('%64%6f%63%75%6d%65%6e%74%2e%77%72%69%74%65%28%27%3c%61%20%68%72%65%66%3d%22%6d%61%69%6c%74%6f%3a%6d%65%40%64%6f%6d%61%69%6e%2e%63%6f%6d%22%3e%4d%79%20%65%6d%61%69%6c%3c%2f%61%3e%27%29%3b'))</script>
      #
      #   mail_to "me@domain.com", "My email", :encode => "hex"  # =>
      #     <a href="mailto:%6d%65@%64%6f%6d%61%69%6e.%63%6f%6d">My email</a>
      #
      # You can also specify the cc address, bcc address, subject, and body parts of the message header to create a complex e-mail using the
      # corresponding +cc+, +bcc+, +subject+, and +body+ <tt>html_options</tt> keys. Each of these options are URI escaped and then appended to
      # the <tt>email_address</tt> before being output. <b>Be aware that javascript keywords will not be escaped and may break this feature
      # when encoding with javascript.</b>
      # Examples:
      #   mail_to "me@domain.com", "My email", :cc => "ccaddress@domain.com", :bcc => "bccaddress@domain.com", :subject => "This is an example email", :body => "This is the body of the message."   # =>
      #     <a href="mailto:me@domain.com?cc="ccaddress@domain.com"&bcc="bccaddress@domain.com"&body="This%20is%20the%20body%20of%20the%20message."&subject="This%20is%20an%20example%20email">My email</a>
      def mail_to(email_address, name = nil, html_options = {})
        html_options = html_options.stringify_keys
        encode = html_options.delete("encode")
        cc, bcc, subject, body = html_options.delete("cc"), html_options.delete("bcc"), html_options.delete("subject"), html_options.delete("body")

        string = ''
        extras = ''
        extras << "cc=#{CGI.escape(cc).gsub("+", "%20")}&" unless cc.nil?
        extras << "bcc=#{CGI.escape(bcc).gsub("+", "%20")}&" unless bcc.nil?
        extras << "body=#{CGI.escape(body).gsub("+", "%20")}&" unless body.nil?
        extras << "subject=#{CGI.escape(subject).gsub("+", "%20")}&" unless subject.nil?
        extras = "?" << extras.gsub!(/&?$/,"") unless extras.empty?

        if encode == 'javascript'
          tmp = "document.write('#{content_tag("a", name || email_address, html_options.merge({ "href" => "mailto:"+email_address.to_s+extras }))}');"
          for i in 0...tmp.length
            string << sprintf("%%%x",tmp[i])
          end
          "<script type=\"text/javascript\" language=\"javascript\">eval(unescape('#{string}'))</script>"
        elsif encode == 'hex'
          for i in 0...email_address.length
            if email_address[i,1] =~ /\w/
              string << sprintf("%%%x",email_address[i])
            else
              string << email_address[i,1]
            end
          end
          content_tag "a", name || email_address, html_options.merge({ "href" => "mailto:#{string}#{extras}" })
        else
          content_tag "a", name || email_address, html_options.merge({ "href" => "mailto:#{email_address}#{extras}" })
        end
      end

      # Returns true if the current page uri is generated by the options passed (in url_for format).
      def current_page?(options)
        url_for(options) == @request.request_uri
      end

      private
        def convert_confirm_option_to_javascript!(html_options)
          if confirm = html_options.delete("confirm")
            html_options["onclick"] = "return confirm('#{confirm.gsub(/'/, '\\\\\'')}');"
          end
        end

        # Processes the _html_options_ hash, converting the boolean
        # attributes from true/false form into the form required by
        # HTML/XHTML.  (An attribute is considered to be boolean if
        # its name is listed in the given _bool_attrs_ array.)
        #
        # More specifically, for each boolean attribute in _html_options_
        # given as:
        #
        #     "attr" => bool_value
        #
        # if the the associated _bool_value_ evaluates to true, it is
        # replaced with the attribute's name; otherwise the attribute is
        # removed from the _html_options_ hash.  (See the XHTML 1.0 spec,
        # section 4.5 "Attribute Minimization" for more:
        # http://www.w3.org/TR/xhtml1/#h-4.5)
        #
        # Returns the updated _html_options_ hash, which is also modified
        # in place.
        #
        # Example:
        #
        #   convert_boolean_attributes!( html_options,
        #                                %w( checked disabled readonly ) )

        def convert_boolean_attributes!(html_options, bool_attrs)
          bool_attrs.each { |x| html_options[x] = x if html_options.delete(x) }
          html_options
        end

    end
  end
end
