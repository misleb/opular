# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use Opal in this file: http://opalrb.org/
#
#
# Here's an example view class for your controller:
#
class HomeView
  attr_reader :element

  def initialize(selector = '.home-index', parent = Element)
    @element = parent.find(selector)
    setup
  end

  def setup
    lam = ->(e) {
      HTTP.get("/api") do |response|
        e.current_target.html += response.json.map { |i| i[:value] }.join(', ')
      end
    }

    all_links.on :click do |event|
      event.prevent_default

      event.current_target.html += "; "
      lam.call(event)
    end
  end

  private

  def all_links
    @all_links ||= element.find('a')
  end
end
