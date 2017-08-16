json.extract! user, :id, :username, :email, :easyauth_uid, :created_at, :updated_at
json.url user_url(user, format: :json)
