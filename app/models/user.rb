class User < ApplicationRecord
	validates_presence_of :easyauth_uid, message: "Are you using TLS?"
	validates_presence_of :email
	validates_presence_of :username
end
