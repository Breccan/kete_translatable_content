require 'kete_translatable_content'

module KeteTranslatableContentHelper
  def kete_translatable_content?
    translatable_controllers = TRANSLATABLES.keys.collect(&:pluralize)
    translatable_controllers.include?(params[:controller]) &&
      TRANSLATABLES[params[:controller].singularize]['views'].include?(params[:action])
  end
end
