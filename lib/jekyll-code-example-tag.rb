module Jekyll
  module CodeExampleTags

    def self.code_example_dir(site) 
      site.fetch('code_example_dir', 'code_examples')
    end

    # Returns a hash of available code examples (per language) for the provided example name
    def self.code_examples(example_name, site)
      # Collect all relevant files
      examples_root = code_example_dir(site)

      code_folders = Dir.entries(examples_root).select do |entry|
        File.directory? File.join(examples_root, entry) and !(entry =='.' || entry == '..')
      end

      examples = {}
      code_folders.each do |lang|
        code_folder = File.join(examples_root, lang)
        example_file = Dir.entries(code_folder).find do |entry|
          File.file? File.join(code_folder, entry) and entry == example_name
        end
        if example_file
          examples[lang] = File.join(code_folder, example_file)
        end
      end

      examples
    end

    def self.buttons_markup(examples)
      menu_items = ""
      examples.each_key do |lang|
        menu_items << "<li><a href='#' class='button' target='#{lang}'>#{lang.capitalize}</a></li>"
      end
      <<EOF
            <div class="buttons examples">
              <ul>
                #{menu_items}
              </ul>
            </div>
EOF
    end

    def self.example_markup(language, content)
      <<EOF
          <div class="highlight example #{language}">
            <pre><code class="language #{language}" data-lang="#{language}">#{content}</code></pre>
          </div>
EOF

    end

    def self.wrap_examples_div(content)
      "<div class='code-examples'>#{content}</div>"
    end

    class CodeExampleTag < Liquid::Tag
      def initialize(tag_name, example_name, tokens)
          @example_name = example_name.strip
          super
      end

      def render(context)

        examples = Jekyll::CodeExampleTags::code_examples(@example_name, context['site'])

        # Build the code example elements
        output = Jekyll::CodeExampleTags::buttons_markup(examples)
        examples.each do |lang, path|
          example_content = File.read(path)
          output << Jekyll::CodeExampleTags::example_markup(lang, example_content)
        end

        output = Jekyll::CodeExampleTags::wrap_examples_div(output)
      end
    end

    class AllPageCodeExamplesTag < Liquid::Tag
      def render(context)
        examples = {}
        context['page']['content'].scan(/\{%\s*code_example (\S+)\s*%\}/) do |name|
          more_examples = Jekyll::CodeExampleTags::code_examples(name[0], context['site'])
          examples.merge!(more_examples){|key, pre_example, new_example| "#{pre_example}\n#{new_example}"}
        end

        # Build the code example elements
        output = Jekyll::CodeExampleTags::buttons_markup(examples)
        examples.each do |lang, paths|
          example_content = ""
          for path in paths.split("\n")
            example_content << File.read(path)
          end
          output << Jekyll::CodeExampleTags::example_markup(lang, example_content)
        end

        output = Jekyll::CodeExampleTags::wrap_examples_div(output)
      end
    end

    class CodeExamplesJsFile < Jekyll::StaticFile
      def write(dest)

        if File.file?(File.join(FileUtils.pwd, @dir, @name))
          in_path = File.join(FileUtils.pwd, @dir, @name)
        else
          in_path = File.join(File.dirname(__FILE__), @dir, @name)
        end
        dest_path = File.join(dest, @dir, @name)

        FileUtils.mkdir_p(File.dirname(dest_path))
        content = File.read(in_path)
        File.open(dest_path, 'w') do |f|
          f.write(content)
        end
      end
    end

    class CodeExamplesJsGenerator < Jekyll::Generator
      safe true
    
      def generate(site)
        name = 'jekyll-code-example-buttons.js'
        destination = '/js/'
        site.static_files << CodeExamplesJsFile.new(site, site.source, destination, name)
      end
    end
  end
end

Liquid::Template.register_tag('code_example', Jekyll::CodeExampleTags::CodeExampleTag)
Liquid::Template.register_tag('all_page_code_examples', Jekyll::CodeExampleTags::AllPageCodeExamplesTag)
