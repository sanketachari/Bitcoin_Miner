defmodule MiningManager do

    def startMining(leadingZeros, offset \\ 0, sender \\ nil) do
     
        prefix = "sanketachari;"
        workLoad = 100000000
        noofActors = System.schedulers_online() - 1

        IO.puts "Mining started"

        Enum.each(0..noofActors, fn x -> 
            localMiner = spawn(LocalMiner, :mine, [self()])
            startNonce = Integer.to_string(workLoad * (x + offset) , 36)
            endNonce = Integer.to_string(String.to_integer(startNonce, 36) + workLoad - 1, 36)
            send localMiner, {leadingZeros, prefix,  String.downcase(startNonce), String.downcase(endNonce), (x + offset)} end)
       
        loop(sender)
    end

    def loop(sender) do
        receive do
            msg ->  
                if(sender == nil) do
                    IO.puts msg
                else
                    send sender, msg
                end
        end
        loop(sender)
    end

    # worker will use this to get work from server
    def getWork(ip) do

        # Start local node
        {:ok, ifs} = :inet.getif()
        ips = Enum.map(ifs, fn {ip, _broadaddr, _mask} -> ip end)
        [localIP | ip2] = Enum.map(ips, fn x -> to_string(:inet.ntoa(x)) end)
        
        # Extract ip of local machine
        case localIP do
            "127.0.0.1" -> localIP = to_string(ip2)
            _ ->
        end

        localNode = String.to_atom("w213@" <> localIP)

        case Node.start(localNode) do
            {:ok, _} -> Node.set_cookie(Node.self, :"foo")
            {:error, _} ->  IO.puts "Unable to start node locally"
        end

        #Contact server for work
        serverNode = String.to_atom("w213@" <> ip)

        case Node.connect(serverNode) do
            true -> :ok
            reason ->
                IO.puts "Could not connect to server, reason: #{reason}"
                System.halt(0)
        end

        # Spawn node and connect to server
        Node.spawn_link(serverNode, MiningManager, :generateWork, [self(), System.schedulers_online()])

        receive do
            {leadingZeros, noofServerActors, sender} -> 
                startMining(leadingZeros, noofServerActors, sender)
        end
    end

    # server will generate work and send it to the worker
    def generateWork(worker, clientCores) do    

        :ets.insert(:user_lookup, {"testInput", 10}) 
        case :ets.match(:user_lookup,  {"server",  :"$1"}) do

            [[server]] -> 
                    case :ets.match(:user_lookup,  {"leadingZeros",  :"$1"}) do
                        [[leadingZeros]] -> 
                            case :ets.match(:user_lookup,  {"processorCount",  :"$1"}) do
                                [[existingCores]] ->  
                                    # Node.spawn(MiningManager, )
                                    send worker, {leadingZeros, existingCores, server}
                            end
                    
                        [] -> send worker, {"0", System.schedulers_online(), server} 
                    end
        end
    end

    def storeCores(existingCores, clientCores) do
        """
        receive do
            :ets.insert(:user_lookup, {"processorCount", existingCores +  clientCores}) 
        end
        """
    end
end
