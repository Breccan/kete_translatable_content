require 'mongo_translatable'
require 'kete_translatable_content'
require 'kete_translatable_content_helper'

config.to_prepare do
  kete_translatable_content_ready = true
  TRANSLATABLES.keys.each do |name|
    translatable = name.camelize.constantize.send(:new) rescue false
    kete_translatable_content_ready = translatable && translatable.respond_to?(:original_locale)
    break if kete_translatable_content_ready == false
  end

  # In development/production, we want to only setup stuff if IS_CONFIGURED is true
  # In test mode however, we always want to have it, since IS_CONFIGURED won't be true
  # at this stage, but it will be changed to true after Rails initializes.
  if (IS_CONFIGURED || Rails.env.test?) && kete_translatable_content_ready
    TRANSLATABLES.each do |name, spec_hash|
      args = [:mongo_translate, *spec_hash['translatable_attributes']]
      args << { :redefine_find => spec_hash['redefine_find'] } unless spec_hash['redefine_hash'].nil?
      name.camelize.constantize.send(*args)
    end

    ApplicationController.class_eval do
      helper KeteTranslatableContentHelper

      before_filter :reload_standard_baskets
      def reload_standard_baskets
        Rails.logger.info "[Kete Translatable Content]: Reloading Standard Baskets to be locale aware"
        @site_basket.reload
        @help_basket.reload
        @about_basket.reload
        @documentation_basket.reload
      end

      around_filter :redirect_unless_editing_original_locale
      def redirect_unless_editing_original_locale
        if params[:controller] == 'baskets' && params[:action] == 'edit'
          appropriate_basket # set @basket
          if I18n.locale.to_sym != @basket.original_locale.to_sym
            flash[:error] = I18n.t('kete_translatable.only_edit_original_locale')
            redirect_to params.merge(:locale => @basket.original_locale)
            return false
          end
        end

        yield
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
# load our locales
I18n.load_path += Dir[ File.join(File.dirname(__FILE__), '..', 'config', 'locales', '*.{rb,yml}') ]
