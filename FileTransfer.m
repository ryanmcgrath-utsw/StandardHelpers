classdef FileTransfer < udpCommLink
    %FILETRANSFER class methods to handle transfering of files from one pc
    % to the other using matlab
    
    properties
        file containers.Map % map of all recieving files (sent files are not kept, check superclass udpCommLink)
        fileCallback (1,1) % handle to function that is called when file is recieved (arguments given is file info and FileTransfer obj)
    end
    
    methods
        function obj = FileTransfer(options)
            %FILETRANSFER constructor
            
            % parse inputs
            arguments
                options.clientIP (1,1) string
                options.clientPort (1,1) double = 5555
                options.hostIP (1,1) string = udpCommLink.getHostIP()
                options.hostPort (1,1) double = -1
                
                options.fileCallback (1,1) function_handle = @disp
            end
            
            if options.hostPort == -1
                options.hostPort = options.clientPort;
            end
            
            obj.file = containers.Map('KeyType','uint64','ValueType','any');
            
            obj.setDataFcn(21, @obj.fileRequested)
            obj.setDataFcn(22, @obj.requestReply)
            obj.setDataFcn(23, @obj.fileRecieved)
            
            obj.dataSize = 64064;
            obj.initializeUDP(options.clientIP, options.clientPort, options.hostIP, options.hostPort)
            obj.activeListening = 'on';
            
            if isequal(options.fileCallback, @disp)
                obj.fileCallback = @(f,x) disp([class(x) ' recieved ' f.name]);
            else
                obj.fileCallback = options.fileCallback;
            end
        end
        
        %% recieve files
        function requestFile(obj, clientPath, hostPath)
            %REQUESTFILE gets the other side to send a file from the path
            % on the client to the path on the host
            
            fileKey = randi(255,1,8,'uint8');
            obj.sendData(21, uint8([fileKey, length(clientPath), length(hostPath), clientPath, hostPath]))
            [fileStruct.folder, fileStruct.name, ext] = fileparts(hostPath);
            fileStruct.name = cat(2, fileStruct.name, ext);
            fileStruct.packets = {};
            fileStruct.data = [];
            obj.file(typecast(fileKey,'uint64')) = fileStruct;
        end
        
        function requestReply(obj, msg, ~)
            %REQUESTREPLY client found the file and will be sending it soon
            
            arguments
                obj (1,1) FileTransfer
                msg (1,:) uint8
                ~ % this is just a copy of the obj argument
            end
            
            msg = typecast(msg, 'uint64');
            if msg(1) || msg(2)
                % file found on client prep for transmission
                fileStruct = obj.file(msg(3));
                fileStruct.bytes = msg(1);
                fileStruct.checkSum = msg(2);
                obj.file(msg(3)) = fileStruct;
                
            else
                % file not found let user know
                obj.err(0, 'Requested file was not found on client''s computer')
                % and delete the file from the container map
                remove(obj.file, msg(3));
            end
        end
        
        function fileRecieved(obj, msg, ~)
            %FILERECIEVED file transfer success time to save and check for
            % file integrity
            
            arguments
                obj (1,1) FileTransfer
                msg (1,:) uint8
                ~ % this is just a copy of the obj argument
            end
            
            fileKey = typecast(msg(1:8), 'uint64');
            data = msg(9:end);
            if obj.file(fileKey).bytes ~= length(data)
                obj.err(0, 'File recieved failed count check. File has incorrect number of bytes compared to expected.')
            elseif obj.file(fileKey).checkSum ~= sum(data)
                obj.err(0, 'File recieved failed sum check. Sum of file recieved doesn''t match expected sum.')
            end
            fid = fopen(fullfile(obj.file(fileKey).folder, obj.file(fileKey).name), 'w+');
            cleanup = onCleanup(@(~) fclose(fid));
            fwrite(fid, data);
            if isa(obj.fileCallback,'function_handle')
                obj.fileCallback(obj.file(fileKey), obj);
            end
            remove(obj.file, fileKey)
        end
        
        %% send files
        function fileRequested(obj, msg, ~)
            %FILEREQUESTED other side requested a file, prep everything
            
            arguments
                obj (1,1) FileTransfer
                msg (1,:) uint8
                ~ % this is just a copy of the obj argument
            end
            
            fileKey = typecast(msg(1:8), 'uint64');
            filePath = char(msg(11:11+msg(9)));
            if ~exist(filePath, 'file')
                obj.sendData(22, typecast(uint64([0, 0, fileKey]),'uint8'))
            else
                fid = fopen(filePath);
                cleanup = onCleanup(@(~) fclose(fid));
                data = uint8(fread(fid));
                obj.sendData(22, typecast(uint64([length(data), sum(data), fileKey]),'uint8'))
                pause(0.1)
                obj.sendLargeData(23, [fileKey, data])
            end
        end
    end
end