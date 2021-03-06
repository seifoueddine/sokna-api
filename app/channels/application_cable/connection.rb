module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private
    def find_verified_user
      uid = request.query_parameters[:uid]
      token = request.query_parameters[:token]
      client_id = request.query_parameters[:client]
      slug_id = request.query_parameters[:slug_id]
      user = User.where(slug_id: slug_id).find_by_uid(uid)

      if user && user.valid_token?(token, client_id)
        user
      else
        reject_unauthorized_connection
      end
    end
  end
end
