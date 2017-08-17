class User < ApplicationRecord
	validates_presence_of :easyauth_uid, message: "Are you using TLS?"
end
