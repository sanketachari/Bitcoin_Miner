defmodule Project1 do
  use GenServer

  def main(args \\ []) do

    leadingZeros = ""
    {_, input, _} = OptionParser.parse(args, switches: [])

    if length(input) === 1 do 
      k = List.to_string(input)

      if String.contains? k, "." do
        IO.puts "This is client. Calling server"
        MiningManager.getWork(k)
      else
        IO.puts "Calling Miners"
        {:ok, ifs} = :inet.getif()
        ips = Enum.map(ifs, fn {ip, _broadaddr, _mask} -> ip end)
        [localIP | ip2] = Enum.map(ips, fn x -> to_string(:inet.ntoa(x)) end)

        # Extract ip of local machine
        case localIP do
            "127.0.0.1" -> localIP = to_string(ip2)
            _ ->
        end

        node = String.to_atom("w213@" <> localIP)
        
        case Node.start(node) do
          {:ok, _} -> Node.set_cookie(Node.self, :"foo")
          {:error, _} ->  IO.puts "Unable to start node locally"
        end
      
        leadingZeros = String.duplicate("0", String.to_integer(k))
        :ets.new(:user_lookup, [:set, :public, :named_table])
        :ets.insert(:user_lookup, {"leadingZeros", leadingZeros})
        :ets.insert(:user_lookup, {"server", self()})
        :ets.insert(:user_lookup, {"processorCount", System.schedulers_online()})
        MiningManager.startMining(leadingZeros)
      end
  
    else
      IO.puts "Invalid Arguments. Enter valid k"  
      IO.puts "Use one of the following:"
      IO.puts "\t ./project1 {number}"
      IO.puts "\t ./project1 {HostName/IP address of the remote master miner}"
    end
  end
end
