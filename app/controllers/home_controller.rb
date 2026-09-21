class HomeController < ApplicationController
  before_action :authenticate_user!
  before_action :require_household
  def index
  end
end
