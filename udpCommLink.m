classdef udpCommLink < ErrorLogger
    %UDPCOMMLINK handles udp communication efficiently
    % communication protocol:
    % - designed with datagram communication (does not work for byte style)
    % - uses double style of communication
    % - first two numbers are reserved for data type being sent
    % - max of 10 numbers sent per datagram, 2 of which are reserved (support for larger planned)
    % - if link failed to respond during connect reccomend looping obj.handleMessage()
    % - set up dataFcns to allow for multiple seperate callbacks
    
    properties
        my_status = 0
        link_status = 0
        
        last_sent
        last_recv
        
        UserData % open slot aimed at allowing objects or structures to be 
                 % passed through the activeListening data functions
    end
    
    properties (Dependent)
        activeListening
    end
        
    properties (Hidden)
        my_ip
        my_port
        link_ip
        link_port
        sock = -1
        
        dataSize = 80
        timeOut = 1
        dataFcns = {}
        
        ping = 'Not Connected'
        deleteWatcher
    end
    
    methods
        %% USER FUNCTIONS 
        function initializeUDP(obj, link_ip, link_port, my_ip, my_port, varargin)
            %INITIALIZEUDP sets up the communication settings
            % parse through input
            for ii = 1:2:length(varargin)
                if isequal(varargin{ii}, 'force')
                    force = varargin{ii+1};
                else
                    obj.(varargin{ii}) = varargin{ii+1};
                end
            end
            
            if ~exist('force','var')
                force = 0;
            end
            
            obj.link_ip = link_ip;
            obj.link_port = link_port;
            obj.my_ip = my_ip;
            obj.my_port = my_port;
            
            % attempts to connect to the socket
            obj.my_status = 0;
            obj.connectSocket(force)
            
            % try to connect to link
            obj.link_status = 0;
            obj.connect()
        end
        
        function connect(obj)
            %CONNECT trys to connect to the link
            obj.link_status = 0;
            if obj.sock == -1
                obj.connectSocket()
            end
            if obj.sock ~= -1
                obj.send(0,0,now)
                if obj.wait4msg()
                    obj.handleMessage();
                end
            end
        end
        
        function disconnect(obj,~,~)
            %DISCONNECT call to delete the socket properly plus clean up
            if obj.sock ~= - 1
                obj.send(0,1,now)
                obj.activeListening = 'off';
                if obj.wait4msg()
                    obj.handleMessage();
                end
            end
            obj.my_status = 0;
            obj.sock = -1;
        end
        
        function sendData(obj, dataType, data)
            %SENDDATA user calls this to send information through port
            if obj.my_status && obj.link_status
                obj.send(1, dataType, data)
            end
        end
        
        function set.activeListening(obj,value)
            %set.ACTIVELISTENING acts similar to configure callback use
            % with the sedDataFcn method
            switch value
                case 'on'
                    configureCallback(obj.sock,'datagram',1,@obj.handleMessage)
                case 'off'
                    configureCallback(obj.sock,'off')
                case 'restart'
                    configureCallback(obj.sock,'off')
                    configureCallback(obj.sock,'datagram',1,@obj.handleMessage)
                otherwise
                    obj.err(0,'activeListening can only be set to "on"/"off"/"restart"!')
            end
        end
        
        function value = get.activeListening(obj)
            %get.ACTIVELISTENING set to 'on' if callback is set and 'off' if it is not set
            switch obj.sock.DatagramsAvailableFcnMode
                case 'datagram'
                    value = 'on';
                case 'off'
                    value = 'off';
            end
        end
        
        function setDataFcn(obj, dataType, fcnHandle)
            %SETDATAFCN allows for multiple functions to have specific callbacks
            obj.dataFcns{dataType} = fcnHandle;
        end
        
        function editConnection(obj, prop, value)
            %EDITCONNECTION allows for user to change specific properties 
            % of the connection for both sides of the comm link
            switch prop
                case 'dataSize'
                    obj.send(0,3,value)
                    obj.sock.OutputDatagramSize = value;
                    
                otherwise
                    obj.err(0,'Invalid property given. Check udpCommLink.editConnection for possible property values.')
            end
        end
        
        %% MESSAGE HANDLING
        function [recv, status] = handleMessage(obj,~,~)
            %HANDLEMESSAGE main function to call when recieving data
            % typically shouldn't be called directly instead set up
            % dataFcns and use activeListening = 'on'
            recv = {};
            status = {};
            if ~obj.sock.NumDatagramsAvailable || obj.sock == -1
                return % no data is available (error check)
            end
            recieve = read(obj.sock, obj.sock.NumDatagramsAvailable, 'double');
            recv   = cell(size(recieve));
            status = recv;
            for ii = 1:length(recieve)
                dataRecieved = recieve(ii).Data;
                obj.last_recv = dataRecieved;
                switch dataRecieved(1)
                    case 0 % admin message
                        status{ii} = 1;
                        recv{ii} = obj.adminMessage(dataRecieved(2:end));
                    case 1 % data message
                        [recv{ii}, status{ii}] = obj.dataMessage(dataRecieved(2:end));
                    otherwise % unknown data was sent over
                        status{ii} = 0;
                end
            end
        end
        
        function recv = adminMessage(obj, data)
            %ADMINMESSAGE
            recv = [];
            type = data(1);
            data = data(2:end);
            switch type
                case 0
                    % link is establishing communication
                    obj.link_status = 1;
                    if data
                        obj.send(0,0,0) % confirm link 
                    end
                case 1
                    % link is disconnecting
                    obj.link_status = 0;
                case 2
                    % communication testing
                    if data(2)
                        % link is sending a single ping
                        obj.send(0,1,[data -1])
                    end
                case 3
                    % new dataSize value being used
                    obj.sock.OutputDatagramSize = data(1);
            end
        end
        
        function [recv, status] = dataMessage(obj, data)
            %DATAMESSAGE
            recv = data;
            status = 1;
            if ~isempty(obj.dataFcns) && recv(1)<=length(obj.dataFcns)
                fcnHandle = obj.dataFcns{recv(1)};
                fcnHandle(recv(2:end), obj)
            end
        end
        
        function send(obj, type, subType, data)
            %REPLY send data to link with type and subType appended on front
            write(obj.sock, [type, subType, data], 'double', obj.link_ip, obj.link_port)
            obj.last_sent = [type, subType, data];
        end
        
        %% COMMUNICATION TESTING
        function split = sendPing(obj)
            %SENDPING sends a message then waits for response (finds split)
            write(obj.sock, [0 2 now 1  0], 'double', obj.link_ip, obj.link_port)
            if obj.wait4msg()
                recv = read(obj.sock, obj.sock.NumDatagramsAvailable, 'double');
                recv = recv(end).Data;
                split = (now - recv(3))*60*24*60;
                obj.ping = [num2str(split*1000) ' ms'];
            else
                % other side failed to respond
                split = 0;
                obj.ping = 'Timed Out';
            end
        end
        
        function splits = pingTest(obj, pingCount, display)
            %PINGTEST run mulitple pings to gain network statistics
            if nargin < 3
                display = 1;
            end
            if display
                feedback = waitbar(0,'Running Communication Test');
            end
            splits = zeros(1, pingCount);
            for ii = 1:pingCount
                splits(ii) = obj.sendPing();
                if display
                    waitbar(ii/pingCount,feedback)
                end
            end
            close(feedback)
            runTime  = sum(splits);
            avgSplit = mean(nonzeros(splits))*1000;
            stdSplit = std(nonzeros(splits))*1000;
            medSplit = median(nonzeros(splits))*1000;
            dropped  = sum(splits==0);
            header  = [' Ping Test Results  ' newline repmat('=',1,25) newline];
            results = ['          Run Time: ' num2str(runTime)   ' sec' newline ...
                       '      Average Ping: ' num2str(avgSplit)  ' ms'  newline ...
                       'Standard Deviation: ' num2str(stdSplit)  ' ms'  newline ...
                       '       Median Ping: ' num2str(medSplit)  ' ms'  newline ...
                       '      Packets Sent: ' num2str(pingCount)        newline ...
                       '   Packets Dropped: ' num2str(dropped)];
            if display
            	disp([header results])
            end
            obj.ping = [num2str(avgSplit) ' ms'];
        end
        
        function splits = writeTest(obj, writeCount, display)
            %PINGTEST run mulitple pings to gain network statistics
            if nargin < 3
                display = 1;
            end
            if display
                feedback = waitbar(0,'Running Write Test');
            end
            splits = zeros(1, writeCount);
            for ii = 1:writeCount
                split = tic;
                obj.send(0, 2, [now 0])
                splits(ii) = toc(split);
                if display
                    waitbar(ii/writeCount,feedback)
                end
            end
            close(feedback)
            runTime  = sum(splits);
            avgSplit = mean(nonzeros(splits))*1000;
            stdSplit = std(nonzeros(splits))*1000;
            medSplit = median(nonzeros(splits))*1000;
            dropped  = sum(splits==0);
            header  = [' Ping Test Results  ' newline repmat('=',1,25) newline];
            results = ['          Run Time: ' num2str(runTime)   ' sec' newline ...
                       '      Average Ping: ' num2str(avgSplit)  ' ms'  newline ...
                       'Standard Deviation: ' num2str(stdSplit)  ' ms'  newline ...
                       '       Median Ping: ' num2str(medSplit)  ' ms'  newline ...
                       '      Packets Sent: ' num2str(writeCount)       newline ...
                       '   Packets Dropped: ' num2str(dropped)];
            if display
            	disp([header results])
            end
            obj.ping = [num2str(avgSplit) ' ms'];
        end
        
        %% MISC FUNCTIONS
        function connectSocket(obj, force)
        % attempts to connect to the socket
            try
                obj.sock = udpport("datagram", "IPV4", "LocalHost",obj.my_ip, "LocalPort",obj.my_port, "OutputDatagramSize",obj.dataSize);
                obj.deleteWatcher = addlistener(obj,'ObjectBeingDestroyed',@obj.disconnect);
                obj.my_status = 1;
            catch ME
                obj.sock = -1;
                obj.err(force, 'Unable to generate UDP socket', ME)
                obj.my_status = 0;
            end
        end
        
        function reformSocket(obj)
            %REFORMSOCKET disconnects and recreates the socket then
            % connects again using the same active listening protocol
            % To be done when uneditable part of the socket needs to be
            % changed like the port number
            activeListeningStatus = obj.activeListening;
            obj.disconnect()
            obj.connect()
            obj.activeListening = activeListeningStatus;
        end
        
        function waitTime = wait4msg(obj, timeOut)
            %WAIT4MSG pauses code waiting for message from link 
            % outputs either time waited or 0 if msg never recieved (timeout)
            if nargin < 2
                timeOut = obj.timeOut;
            end
            waiting = tic;
            while ~obj.sock.NumDatagramsAvailable && toc(waiting)<timeOut; end
            if obj.sock.NumDatagramsAvailable
                waitTime = toc(waiting);
            else
                waitTime = 0;
            end
        end
        
        function delete(obj)
            obj.disconnect()
        end
    end
end