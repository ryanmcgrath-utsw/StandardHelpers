classdef FileTransfer < udpCommLink
    %FILETRANSFER class methods to handle transfering of files from one pc
    % to the other using matlab
    
    properties
        file = struct;
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
            end
            
            if options.hostPort == -1
                options.hostPort = options.clientPort;
            end
            
            obj.setDataFcn(1,@obj.fileRequested)
            obj.setDataFcn(2,@obj.requestReply)
            obj.setDataFcn(3,@obj.fileRecieved)
            
            obj.dataSize = 64064;
            obj.initializeUDP(options.clientIP, options.clientPort, options.hostIP, options.hostPort)
            obj.activeListening = 'on';
        end
        
        %% recieve files
        function requestFile(obj, clientPath, hostPath)
            %REQUESTFILE gets the other side to send a file from the path
            % on the client to the path on the host
            
            obj.sendData(1, uint8([clientPath ' ~ ' hostPath]))
            [obj.file.folder, obj.file.name, ext] = fileparts(hostPath);
            obj.file.name = cat(2, obj.file.name, ext);
            obj.file.packets = {};
            obj.file.data = [];
        end
        
        function requestReply(obj, msg, ~)
            %REQUESTREPLY client found the file and will be sending it soon
            
            if any(msg)
                % file found on client prep for transmission
                obj.file.bytes = typecast(msg(1:8), 'uint64');
                obj.file.checkSum = typecast(msg(9:16), 'uint64');
            else
                % file not found let user know
                obj.err(0, 'Requested file was not found on client''s computer')
            end
        end
        
        function fileRecieved(obj, msg, ~)
            %FILERECIEVED file transfer success time to save and check for
            % file integrity
            
            if obj.file.bytes ~= length(msg)
                obj.err(0, 'File recieved failed count check. File has incorrect number of bytes compared to expected.')
            elseif obj.file.checkSum ~= sum(msg)
                obj.err(0, 'File recieved failed sum check. Sum of file recieved doesn''t match expected sum.')
            end
            obj.file.data = msg;
            fid = fopen(fullfile(obj.file.folder, obj.file.name), 'w+');
            cleanup = onCleanup(@(~) fclose(fid));
            fwrite(fid, msg);
            debug('WORKED :)')
        end
        
        %% send files
        function fileRequested(obj, msg, ~)
            %FILEREQUESTED other side requested a file, prep everything
            
            obj.transfering = 1;
            paths = split(char(msg),' ~ ');
            if ~exist(paths{1}, 'file')
                obj.sendData(2, typecast(uint64([0 0]),'uint8'))
            else
                obj.file = dir(paths{1});
                fid = fopen(paths{1});
                cleanup = onCleanup(@(~) fclose(fid));
                obj.file.data = uint8(fread(fid));
                obj.sendData(2, typecast(uint64([obj.file.bytes sum(obj.file.data)]),'uint8'))
                pause(0.1)
                obj.sendLargeData(3, obj.file.data)
            end
        end
    end
end