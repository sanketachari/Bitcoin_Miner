defmodule LocalMiner do

    def mine(manager) do
        receive do
            {leadingZeros, prefix, startNonce, endNonce, id} ->
                mineHelper(manager, leadingZeros, prefix, startNonce, endNonce, id)
        end
    end

    def mineHelper(manager, leadingZeros, prefix, startNonce, endNonce, id) do
        bitcoin = prefix <> startNonce
        output_str = Base.encode16(:crypto.hash(:sha256, bitcoin))

        if String.to_integer(startNonce, 36) <= String.to_integer(endNonce, 36) do
            if String.starts_with?(output_str, leadingZeros) do
                # send manager, Integer.to_string(id) <> " " <>String.downcase(prefix <> startNonce <> " " <> output_str)
                send manager, String.downcase(prefix <> startNonce <> "\t" <> output_str)
            end
            newStartNonce = Integer.to_string(String.to_integer(startNonce, 36) + 1, 36)
            mineHelper(manager, leadingZeros, prefix, String.downcase(newStartNonce), endNonce, id) 
        end 
    end
end
