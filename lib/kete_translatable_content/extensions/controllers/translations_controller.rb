TranslationsController.class_eval do
  uses_tiny_mce :options => Kete.translatable_tiny_mce_options, :only => %w{ new edit }
end
