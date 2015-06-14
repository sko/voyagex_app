class TestController < ApplicationController
  include ::AuthUtils
  include ::GeoUtils
  
  layout 'test'

  def javascript
  end

end
