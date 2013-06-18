require 'i18n/one_sky/client_base'
require 'yaml'

module I18n
  module OneSky
    # A class to deal with the OneSky apis
    # it encapsulates the logic of I18n::Backend::ActiveRecord
    class SimpleClient < ClientBase
      include I18n::Backend::Flatten

      # Store all translations from OneSky in YAMl files.
      def download(yaml_path)
        puts "Downloading translations for I18n Simple Backend:"

        platform_locales.each do |locale|
          locale_code  = locale["locale"]
          local_name   = locale["name"]["local"]
          english_name = locale["name"]["eng"]

          if locale_code == platform_base_locale
            # We skip the base locale.
            next
          else
            yaml = platform.translation.download_yaml(locale_code)
            yaml_file_name = "#{locale_code}_one_sky.yml"
            yaml.force_encoding('utf-8')

            if yaml.empty?
              puts "  locale: #{locale_code} - not downloading because it is empty (the old one would be deleted)"
              File.delete(yaml_file_name) if File.exist?(yaml_file_name)
            else
              puts "  locale: #{locale_code}, file: #{yaml_file_name}"

              File.open(File.join(yaml_path, yaml_file_name), "w") do |f|
                f.puts "# PLEASE DO NOT EDIT THIS FILE."
                f.puts "# This was downloaded from OneSky. Log in to your OneSky account to manage translations on their website."
                f.puts "# Language code: #{locale_code}"
                f.puts "# Language name: #{local_name}"
                f.puts "# Language English name: #{english_name}"
                f.write yaml
              end
            end
          end
        end
      end

      # Scan all yaml files for keys in the default locale, and push them to OneSky.
      def upload(yaml_path)
        upload_phrases(all_phrases(yaml_path))
      end

      def all_phrases(yaml_path)
        phrases = {}
        Dir.glob("#{yaml_path}/**/*.yml").each do |path|
          hash = YAML::load(File.read(path))
          phrases.deep_merge!(hash[I18n.default_locale.to_s]) if hash.has_key?(I18n.default_locale.to_s)
        end
        flatten_phrases(phrases)
      end
      memoize :all_phrases

      protected

      def flatten_phrases(phrases)
        hash = {}
        flatten_keys(phrases, true) do |key, value|
          hash[key.to_s] = value unless value.is_a?(Hash)
        end
        hash
      end
    end
  end
end

