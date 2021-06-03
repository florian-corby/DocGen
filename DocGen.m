% ======================================================================= %
% ========================= LA TOOLBOX DOCGEN =========================== %
% ======================================================================= %

%                    -------------------------                            %
% Auteurs: Marien Couvertier (script original), Florian Legendre (màj)    %
%                                                                         %
% Objectif: Fournir des fonctions globales utilisées dans DocGenScript.m  %
% pour mettre à jour la documentation d'un projet.                        %
%                                                                         %
% IMPORTANT: Modifiez les variables globales dans "properties" ci-dessous %
%            selon votre système                                          %
%                                                                         %
% IMPORTANT 2: Si vous êtes sous Linux, allez dans PathsTB.m pour         %
%              configurer le caractère de séparation des fichiers appelé  %
%              SEP_TOKEN.                                                 %
%                                                                         %
%                    -------------------------                            %


classdef (Abstract) DocGen
    properties (Constant, Access = private)
        GLOBAL_NOTICE_SRC = 'E:\Git\projects\wip\DocGenTest\codes';
        GLOBAL_NOTICE_DEST = 'E:\Git\projects\wip\DocGenTest\docs';
        
        % SI LINUX:
        %RECOVER_HTML_CMD = ['find ' DocGen.GLOBAL_NOTICE_SRC ' | grep .html > List.txt'];
        % SI WINDOWS:
        RECOVER_HTML_CMD = ['dir /s /b ' DocGen.GLOBAL_NOTICE_SRC '\*.html > List.txt'];
        
        DOC_NAME = 'Notice';
    end
    
    methods(Static)
        % ============= GESTION DES NOTICES ============= %
        function deleteNotice(path)
            cd(path);
            rmdir(DocGen.DOC_NAME, 's');
        end
        
        function notice(path, eval)
            UtilsTB.clearScript();
            cd(path);
            
            % ---------- On récupère le nom du dossier ---------- %
            htap = flip(path);
            moN = strtok(htap, PathsTB.getSepToken());
            Nom = flip(moN);
            
            % ---------- On récupère les noms des scripts du dossier ---------- %
            FileInfos = FilesTB.getFiles(path, '*.m', "");
            k=0;
            for i=1:length(FileInfos)
                if FileInfos(i).isdir==0 %pour gérer les sous dossiers présents
                    k=k+1;
                    ListF{k,1}=FileInfos(i).name;
                end
            end
            
            % ---------- On prépare les options de publication ---------- %
            publishOptions.format='html';
            mkdir(DocGen.DOC_NAME);
            publishOptions.outputDir=[path PathsTB.getSepToken() DocGen.DOC_NAME];
            publishOptions.evalCode = eval;
            
            % ---------- On prépare le contenu de l'index ---------- %
            % Header du dossier maître (le nom du dossier dont on génère la doc):
            Header = ['%% ' Nom];
            filename = ['Index' Nom '.m'];
            fid = fopen(filename,'wt');
            
            % Titre du dossier:
            fprintf(fid,'%s\n',Header);
            fprintf(fid,'%s\n\n','%% Main Functions');
            fprintf(fid,'%s\n','%%');
            
            
            % ---------- On publie les fichiers ---------- %
            % Préallocation:
            nbFichiers = numel(ListF);
            linei=cell(nbFichiers,1);
            for i=1:nbFichiers
                % Création de l'index (cf. Markup) par une bullet list
                % (% *) et hyperliens (< ... >):
                linei{i,1} = ['% * <' ListF{i}(1:end-2) '.html ' ListF{i}(1:end-2) '>'];
                fprintf(fid,'%s\n',linei{i});
            end
            
            % Publication:
            fclose(fid);
            for i=1:nbFichiers
                publish(ListF{i},publishOptions);
            end
            
            %  ---------- On publie l'index ---------- %
            publish(filename,publishOptions);
            
            % --------- Nettoyage des fichiers devenus inutiles --------- %
            delete(filename);
        end
        
        function noticeGlobale(isIndexExhaustive)
            UtilsTB.clearScript();
            
            addpath(genpath(DocGen.GLOBAL_NOTICE_DEST))
            cd(DocGen.GLOBAL_NOTICE_DEST)
            
            % ----------------- Récupération des données ---------------- %
            [~,~]=dos(DocGen.RECOVER_HTML_CMD);
            LISTE=importdata('List.txt');
            
            h=0;
            for i=1:numel(LISTE)
                A{i,1}=strfind(LISTE{i,1},'Index');
                if ~isempty(A{i,1})
                    h=h+1;
                    ListeIndex{h,1}=LISTE{i,1};
                    
                    ListFlip = flip(ListeIndex{h,1});
                    moN = strtok(ListFlip,PathsTB.getSepToken());
                    Nom{h,1} = flip(moN);
                end
            end
            
            % ---------- On prépare les options de publication ---------- %
            publishOptions.format = 'html';
            publishOptions.outputDir = DocGen.GLOBAL_NOTICE_DEST;
            publishOptions.evalCode = false;
            
            % ---------- On crée le script (.m) de l'index global qui sera publié ---------- %
            filename = ('IndexGlobal.m');
            fid = fopen(filename,'wt');
            
            % ---------- On prépare le contenu de l'index global (son .m) ---------- %
            fprintf(fid,'%s\n\n','%% Index Global');
            fprintf(fid,'%s\n\n','%% Purpose');
            fprintf(fid,'%s\n','% Index global de toute la documentation des fonctions contenues dans les différents dossiers');
            fprintf(fid,'%s\n\n','%% Main Index');
            fprintf(fid,'%s\n','%%');
            
            %  ---------- On publie l'index global ---------- %
            % Préallocation:
            DocGen.makeIndexGlobal(fid, isIndexExhaustive);
            
            % Publication:
            publish(filename,publishOptions);
            
            % --------- Nettoyage des fichiers devenus inutiles --------- %
            delete List.txt;
            delete IndexGlobal.m;
        end

        
        % ============== A TRIER ============= %
        function globalIndexArray = globalIndexArrMake(subpathsList)
            % Init Data structures %
            appendIdx = 1;
            nbSubpaths = numel(subpathsList);
            precPathRow = PathsTB.explodeSubpath(subpathsList{1}, PathsTB.getSepToken());
            nbNodes = numel(precPathRow);
            for i=1:nbNodes
                nodePath = [DocGen.GLOBAL_NOTICE_SRC PathsTB.getSepToken() ...
                            PathsTB.concatSubpathFromNodesRow(precPathRow, 1, i)];
                globalIndexArray{appendIdx} = [i, precPathRow(i), nodePath];
                appendIdx = appendIdx + 1;
            end
            
            % Global index making %
            for i=2:nbSubpaths
                currentSubpathRow = PathsTB.explodeSubpath(subpathsList{i}, PathsTB.getSepToken());
                nbNodes = numel(currentSubpathRow);
                
                updatePrecPat = false;
                for j=1:nbNodes
                    if j > numel(precPathRow) || ~strcmp(precPathRow(j), currentSubpathRow(j))
                        updatePrecPat = true;
                    end
                    
                    if updatePrecPat
                        nodePath = [DocGen.GLOBAL_NOTICE_SRC PathsTB.getSepToken() ...
                            PathsTB.concatSubpathFromNodesRow(currentSubpathRow, 1, j)];
                        globalIndexArray{appendIdx} = [j, currentSubpathRow(j), nodePath];
                        precPathRow(j) = currentSubpathRow(j);
                        appendIdx = appendIdx + 1;
                    end
                end
            end
        end
        
        function newPos = generateHTML_aux(globalIndexArray, fid, pos)
            fprintf(fid, '\n%% \t<ul>');
            
            while pos <= size(globalIndexArray, 2)
                % ~~~~~~~~ GESTION VARIABLES ~~~~~~~~ %
                % Pour la lisibilité de ce code %
                currentNodeDepth = globalIndexArray{pos}{1};
                currentNodeName = globalIndexArray{pos}{2};
                currentNodePath = globalIndexArray{pos}{3};
                
                % Essentiel pour gérer les fermetures de balise %
                if(pos+1 <= size(globalIndexArray, 2))
                    nextDepth = globalIndexArray{pos+1}{1};
                else
                    nextDepth = 0;
                end
                
                % ~~~~~~~~ GESTION HTML ~~~~~~~~ %
                % Ouverture d'une entrée %
                fprintf(fid, '\n%% \t<li>');
                
                % Gestion du contenu des entrées %
                if contains(currentNodeName, '.html')
                    fprintf(fid, '<a href="file:///%s">%s</a>', currentNodePath, currentNodeName);
                else
                    fprintf(fid, '%s', currentNodeName);
                end
                
                % Fermeture des entrées selon la profondeur %
                if(currentNodeDepth < nextDepth)
                    pos = DocGen.generateHTML_aux(globalIndexArray, fid, pos+1);
                elseif(currentNodeDepth > nextDepth)
                    for i=1:currentNodeDepth-nextDepth
                        fprintf(fid, '\n%% </li>\n%% </ul>');
                    end
                    
                    if nextDepth ~= 0
                        fprintf(fid, '\n%% </li>');
                    end
                    break;
                else 
                    fprintf(fid, '\n%% </li>');
                end
                
                % On boucle %
                pos = pos+1;
            end
            
            newPos = pos;
        end
        
        function generateHTML(globalIndexArray, fid)
            fprintf(fid, '%% <html>');
            if(size(globalIndexArray) ~= 0)
                [~] = DocGen.generateHTML_aux(globalIndexArray, fid, 1);
            end
            fprintf(fid, '\n%% </html>');
            
            fclose(fid);
        end
        
        function makeIndexGlobal(fid, isExhaustive)
            UtilsTB.clearScript();
            FilesTB.getFiles(DocGen.GLOBAL_NOTICE_SRC, '*.html', 'List.txt');
            
            if ~isExhaustive
                indexList = PathsTB.selectFromPaths('Index', 'List.txt');
            else
                indexList=importdata('List.txt');
            end

            subPathsList = PathsTB.cropPaths(indexList, [DocGen.GLOBAL_NOTICE_SRC '\']);
            globalIndexArray = DocGen.globalIndexArrMake(subPathsList);
            DocGen.generateHTML(globalIndexArray, fid);
        end     
    end
end