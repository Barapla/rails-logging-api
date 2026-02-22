class JsonWebToken
    class << self
        def encode(payload, expiry = 24.hours.from_now)
            payload[:expiry] = expiry.to_i
            secret_key_base = "658e2b92bedd980e83c41bc5548d76eac917a2428373b3a995dd9509392d4681330890e7201366773ce9622442df4be689ddbc102a23f8f52aa97c2e5a760603"
            JWT.encode(payload, secret_key_base)
        end
        
        def decode(token)
            secret_key_base = "658e2b92bedd980e83c41bc5548d76eac917a2428373b3a995dd9509392d4681330890e7201366773ce9622442df4be689ddbc102a23f8f52aa97c2e5a760603"
            body = JWT.decode(token, secret_key_base)[0]
            HashWithIndifferentAccess.new body
        rescue
            nil
        end
    end
end
