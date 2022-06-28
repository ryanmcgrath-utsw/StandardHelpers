classdef udpCommLink < ErrorLogger
    %UDPCOMMLINK handles udp communication efficiently
    % communication protocol:
    % - designed with datagram communication (does not work for byte style)
    % - uses uint8 style of communication (ensure proper data type)
    % - first two numbers are reserved for data type being sent
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
        
        longDATA_in  containers.Map % map of longDATA transfers this side is recieving
        longDATA_out containers.Map % map of longDATA transfers this side is sending
        longDATA_timer timer        % timer to ensure longDATA gets transfered
        
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
            
            obj.longDATA_in  = containers.Map('KeyType','uint32', 'ValueType','any');
            obj.longDATA_out = containers.Map('KeyType','uint32', 'ValueType','any');
            
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
            
            % set up longDATA_timer
            obj.longDATA_timer = timer();
            obj.longDATA_timer.Period = 0.5;
            obj.longDATA_timer.ExecutionMode = 'FixedSpacing';
            obj.longDATA_timer.Name = 'UDP_longDATA_timer';
            obj.longDATA_timer.TimerFcn = @(~,~)obj.checkLongDATA;
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
            
            arguments
                obj (1,1) udpCommLink
                dataType (1,1) uint8
                data (1, :) uint8
            end
            
            if length(data) > obj.dataSize
                obj.err(0,'Data is to large to be sent using sendData. Please edit dataSize (editConnection) or use sendLargeData')
            end
            if obj.my_status && obj.link_status
                obj.send(1, dataType, data)
            end
        end
        
        function sendLargeData(obj, dataType, data)
            %SENDLARGEDATA similar to SENDDATA except this is used when the
            % data size would be too large to fit in one packet
            
            arguments
                obj (1,1) udpCommLink
                dataType (1,1) uint8
                data (1, :) uint8
            end
            
            packetSize = obj.dataSize-14;
            packetsRequired = ceil(length(data)/packetSize);
            packets = cell(packetsRequired,1);
            startIndx = 1 : packetSize : length(data);
            endIndx = [packetSize : packetSize : length(data), length(data)];
            errorCheck = randi(2^32);
            for ii = 1:packetsRequired
                dataPacket = data(startIndx(ii):endIndx(ii));
                header = [typecast(uint16([ii packetsRequired length(dataPacket)]), 'uint8'), ...
                          typecast(uint32([sum(dataPacket) errorCheck]), 'uint8')];
                packets{ii} = [uint8(2), dataType, header, dataPacket];
            end
            DATA = cell2mat(packets');
            
            write(obj.sock, DATA, 'uint8', obj.link_ip, obj.link_port)
            obj.last_sent = DATA;
            obj.longDATA_out(uint32(errorCheck)) = packets';
        end
        
        function set.activeListening(obj, value)
            %set.ACTIVELISTENING acts similar to configure callback use
            % with the sedDataFcn method
            
            if obj.my_status
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
            else
                obj.err(0,'Must be connected to socket before editing activeListening')
            end
        end
        
        function value = get.activeListening(obj)
            %get.ACTIVELISTENING set to 'on' if callback is set and 'off' if it is not set
            if obj.my_status
                switch obj.sock.DatagramsAvailableFcnMode
                case 'datagram'
                    value = 'on';
                case 'off'
                    value = 'off';
                end
            else
                value = 'disconnected';
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
                    obj.send(0,3,typecast(uint64(value),'uint8'))
                    obj.sock.OutputDatagramSize = value+2;
                    obj.dataSize = value;
                    
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
            recieve = read(obj.sock, obj.sock.NumDatagramsAvailable, 'uint8');
            recv   = cell(size(recieve));
            status = recv;
            for ii = 1:length(recieve)
                type = recieve(ii).Data(1);
                subType = recieve(ii).Data(2);
                data = uint8(recieve(ii).Data(3:end));
                obj.last_recv = recieve(ii).Data;
                switch type
                    case 0 % admin message
                        status{ii} = 1;
                        recv{ii} = obj.adminMessage(subType, data);
                    case 1 % data message
                        [recv{ii}, status{ii}] = obj.dataMessage(subType, data);
                    case 2 % long data message
                        [recv{ii}, status{ii}] = obj.longDataMessage(subType, data);
                    otherwise % unknown data was sent over
                        status{ii} = 0;
                end
            end
            obj.checkLongDATA()
        end
        
        function checkLongDATA(obj)
            %CHECKLONGDATA checks progress on long data transfers and if
            % additional data packets should be requested
            for key = keys(obj.longDATA_in)
                if iscell(obj.longDATA_in(key{1}))
                    % still need more info from other side
                    missing = cellfun(@(x) isempty(x), obj.longDATA_in(key{1}));
                    obj.requestLongDATA(key{1}, missing)
                else
                    % done with the longDATA transfer
                    obj.send(0,4,[0 typecast(uint32(key{1}), 'uint8')])
                    remove(obj.longDATA_in, key{1});
                end
            end
            if isempty(obj.longDATA_in)
                stop(obj.longDATA_timer)
            end
        end
        
        function recv = adminMessage(obj, type, data)
            %ADMINMESSAGE
            recv = [];
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
                    obj.sock.OutputDatagramSize = typecast(data,'uint64')+2;
                    obj.dataSize = double(typecast(data,'uint64'));
                case 4
                    % request for longData info or to finish request
                    switch data(1)
                        case 0
                            key = typecast(data(2:end), 'uint32');
                            if isKey(obj.longDATA_out, key)
                                remove(obj.longDATA_out, key);
                            end                    
                        case 1
                            key = typecast(data(2:5), 'uint32');
                            if ~isKey(obj.longDATA_out, key)
                                obj.send(0, 4, [uint8(2), typecast(key, 'uint8')])
                            else
                                DATA = obj.longDATA_out(key);
                                missing = logical(data(6:end));
                                if ~isempty(DATA(missing))
                                    write(obj.sock, cell2mat(DATA(missing)), 'uint8', obj.link_ip, obj.link_port)
                                end
                            end
                        
                        case 2
                            key = typecast(data(2:end), 'uint32');
                            if isKey(obj.longDATA_in, key)
                                remove(obj.longDATA_in, key);
                            end
                    end
            end
        end
        
        function [data, status] = dataMessage(obj, type, data)
            %DATAMESSAGE
            status = 1;
            if ~isempty(obj.dataFcns) && type<=length(obj.dataFcns)
                fcnHandle = obj.dataFcns{type};
                fcnHandle(data, obj)
            end
        end
        
        function [data, status] = longDataMessage(obj, type, data)
            %LONGDATAMESSAGE
            status = 1;
            packetNumber = typecast(data(1:2), 'uint16');
            numberOfPackets = typecast(data(3:4), 'uint16');
            packetSize = typecast(data(5:6), 'uint16');
            packetSum = typecast(data(7:10), 'uint32');
            key = typecast(data(11:14), 'uint32');
            data = data(15:end);
            % check sum and size
            if packetSize ~= length(data)
                obj.err(1, 'Packet recieved failed size check')
            elseif packetSum ~= sum(data)
                obj.err(1, 'Packet recieved failed sum check')
            end
            % check if new long data or still recieving
            if ~isKey(obj.longDATA_in, key)
                % new long data
                tempCell = cell(numberOfPackets,1);
                tempCell{packetNumber} = data;
                obj.longDATA_in(key) = tempCell;
            elseif iscell(obj.longDATA_in(key))
                % still recieving
                tempCell = obj.longDATA_in(key);
                tempCell{packetNumber} = data;
                obj.longDATA_in(key) = tempCell;
                if all(cellfun(@(x) ~isempty(x), tempCell))
                    % just finished recieving everything
                    obj.longDATA_in(key) = cell2mat(tempCell');
                    data = obj.longDATA_in(key);
                    if ~isempty(obj.dataFcns) && type<=length(obj.dataFcns)
                        fcnHandle = obj.dataFcns{type};
                        fcnHandle(data, obj)
                    end
                end
            else
                % done with long data
                data = obj.longDATA_in(key);
            end
        end
        
        function requestLongDATA(obj, key, missing)
            %REQUESTLONGDATA request additional attempt at sending long
            % data using the key provided
            arguments
                obj udpCommLink
                key uint32
                missing (1,:) uint8
            end
            if obj.my_port == 5556
                debug('why')
            end
            obj.send(0, 4, [uint8(1) typecast(key, 'uint8') missing])
            if strcmp(obj.longDATA_timer.running, 'off')
                start(obj.longDATA_timer)
            end
        end
        
        function send(obj, type, subType, data)
            %REPLY send data to link with type and subType appended on front
            arguments
                obj (1,1) udpCommLink
                type (1,1) uint8
                subType (1,1) uint8
                data (1,:) uint8
            end
            
            write(obj.sock, [type, subType, data], 'uint8', obj.link_ip, obj.link_port)
            obj.last_sent = [type, subType, data];
        end
        
        %% COMMUNICATION TESTING
%         function split = sendPing(obj)
%             %SENDPING sends a message then waits for response (finds split)
%             write(obj.sock, [0 2 now 1  0], 'double', obj.link_ip, obj.link_port)
%             if obj.wait4msg()
%                 recv = read(obj.sock, obj.sock.NumDatagramsAvailable, 'double');
%                 recv = recv(end).Data;
%                 split = (now - recv(3))*60*24*60;
%                 obj.ping = [num2str(split*1000) ' ms'];
%             else
%                 % other side failed to respond
%                 split = 0;
%                 obj.ping = 'Timed Out';
%             end
%         end
%         
%         function splits = pingTest(obj, pingCount, display)
%             %PINGTEST run mulitple pings to gain network statistics
%             if nargin < 3
%                 display = 1;
%             end
%             if display
%                 feedback = waitbar(0,'Running Communication Test');
%             end
%             splits = zeros(1, pingCount);
%             for ii = 1:pingCount
%                 splits(ii) = obj.sendPing();
%                 if display
%                     waitbar(ii/pingCount,feedback)
%                 end
%             end
%             close(feedback)
%             runTime  = sum(splits);
%             avgSplit = mean(nonzeros(splits))*1000;
%             stdSplit = std(nonzeros(splits))*1000;
%             medSplit = median(nonzeros(splits))*1000;
%             dropped  = sum(splits==0);
%             header  = [' Ping Test Results  ' newline repmat('=',1,25) newline];
%             results = ['          Run Time: ' num2str(runTime)   ' sec' newline ...
%                        '      Average Ping: ' num2str(avgSplit)  ' ms'  newline ...
%                        'Standard Deviation: ' num2str(stdSplit)  ' ms'  newline ...
%                        '       Median Ping: ' num2str(medSplit)  ' ms'  newline ...
%                        '      Packets Sent: ' num2str(pingCount)        newline ...
%                        '   Packets Dropped: ' num2str(dropped)];
%             if display
%             	disp([header results])
%             end
%             obj.ping = [num2str(avgSplit) ' ms'];
%         end
%         
%         function splits = writeTest(obj, writeCount, display)
%             %PINGTEST run mulitple pings to gain network statistics
%             if nargin < 3
%                 display = 1;
%             end
%             if display
%                 feedback = waitbar(0,'Running Write Test');
%             end
%             splits = zeros(1, writeCount);
%             for ii = 1:writeCount
%                 split = tic;
%                 obj.send(0, 2, [now 0])
%                 splits(ii) = toc(split);
%                 if display
%                     waitbar(ii/writeCount,feedback)
%                 end
%             end
%             close(feedback)
%             runTime  = sum(splits);
%             avgSplit = mean(nonzeros(splits))*1000;
%             stdSplit = std(nonzeros(splits))*1000;
%             medSplit = median(nonzeros(splits))*1000;
%             dropped  = sum(splits==0);
%             header  = [' Ping Test Results  ' newline repmat('=',1,25) newline];
%             results = ['          Run Time: ' num2str(runTime)   ' sec' newline ...
%                        '      Average Ping: ' num2str(avgSplit)  ' ms'  newline ...
%                        'Standard Deviation: ' num2str(stdSplit)  ' ms'  newline ...
%                        '       Median Ping: ' num2str(medSplit)  ' ms'  newline ...
%                        '      Packets Sent: ' num2str(writeCount)       newline ...
%                        '   Packets Dropped: ' num2str(dropped)];
%             if display
%             	disp([header results])
%             end
%             obj.ping = [num2str(avgSplit) ' ms'];
%         end
        
        %% MISC FUNCTIONS
        function connectSocket(obj, force)
        % attempts to connect to the socket
            try
                obj.sock = udpport("datagram", "IPV4", "LocalHost",obj.my_ip, "LocalPort",obj.my_port, "OutputDatagramSize",obj.dataSize+2);
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
    
    methods (Static)
        function ip = getHostIP(~)
            %GETHOSTIP grabs the current computers ip info (assumes windows pc)
            
            [~, ip] = system('ipconfig');
            ip = regexp(ip, 'IPv4 Address[. ]+: [0-9.]+[\n\r]', 'match', 'once');
            ip = regexp(ip, '[0-9.]{3,}', 'match', 'once');
        end
    end
end