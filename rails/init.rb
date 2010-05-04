require 'mongo_translatable'
require 'kete_translatable_content'
require 'kete_translatable_content_helper'

config.to_prepare do
  if IS_CONFIGURED
    TRANSLATABLES.each do |name, spec_hash|
      name.camelize.constantize.send(:mongo_translate, spec_hash['translatable_attributes'])
    end

    ApplicationController.class_eval do
      before_filter :reload_standard_baskets
      helper KeteTranslatableContentHelper
      def reload_standard_baskets
        Rails.logger.info "[Kete Translatable Content]: Reloading Standard Baskets to be locale aware"
        @site_basket.reload
        @help_basket.reload
        @about_basket.reload
        @documentation_basket.reload
      end
    end
  end
end

# precedence over a plugin or gem's (i.e. an engine's) app/views
# this is the way to go in most cases,
# but in our case we want to override the app's view.
# so we pop off our gem's app/views directory and put it at the front
kete_translatable_content_views_dir = File.join(directory, 'app/views')
# drop it from it's existing location if it exists
ActionController::Base.view_paths.delete kete_translatable_content_views_dir
# add it to the front of array
ActionController::Base.view_paths.unshift kete_translatable_content_views_dir
