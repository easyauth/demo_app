class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :get_easyauth_id, except: [:new]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)
    @user.easyauth_uid = session[:easyauth_id]

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:username, :email, :easyauth_uid)
    end

    def get_easyauth_id
      @easyauth_id = if request.headers["X-Easyauth-Serial"].nil?
                       nil
                     else
                       require 'openssl'
                       require 'securerandom'
                       require 'uri'
                       require 'json'
                       serial = request.headers["X-Easyauth-Serial"].to_i(16)
                       key = '2d2403a8d60f333ce84a708984a0cd30f231ab03903acc60e7ad8b7554cb153ec9f2218d3c206e5ad217e5c7218c0dcc'
                       nonce = SecureRandom.random_number(2**10)
                       data = nonce.to_s + serial.to_s
                       mac = OpenSSL::HMAC.hexdigest("SHA256", key, data)
                       response = call_easyauth("http://easyauth.org/api/certificates/#{serial}",{ 
                         apikey: '320ece24b1ca866ad9ba65e6e6224b2a730a7ad95ad07c6b1e9ddab64aea05a8e2295361ad8ae66fb79d3ac970c21f2b',
                         nonce: nonce,
                         hmac: mac
                       })
                       parsed_response = JSON.parse(response.body, symbolize_names: true)
                       URI(parsed_response[:certificate][:user]).path.split('/').last.to_i
                     end
      @authenticated_as = User.where(easyauth_uid: @easyauth_id).first if User.where(easyauth_uid: @easyauth_id).any?
      redirect_to '/users/new' and return unless @authenticated_id
      session[:authenticated] = true
      session[:name] = @authenticated_as[:name]
      session[:easyauth_id] = @easyauth_id
    end

    def call_easyauth(uri, parameters)
    require 'net/http'
    require 'uri'
    uri = URI.parse(uri) 
    request = Net::HTTP::Get.new(uri)
    request.body = parameters.to_json
    request['content-type'] = 'application/json'
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  end
end
