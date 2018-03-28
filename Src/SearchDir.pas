unit SearchDir;

interface

uses
  Classes, SysUtils;

type
  TIterateProcedure = reference to procedure(Path:string; SearchRec:TSearchRec; var NeedStop:boolean);

{*
  ���� �� ��ο� �� ���� ������ �ִ� ��� ������ ã�´�.
  ARecursive = false�̸� ���� ������ ã�� �ʴ´�.
}
procedure SearchFiles(APath:string; ARecursive:boolean; AProcedure:TIterateProcedure);

{*
  ���� �� ��ο� �� ������ �ִ� ������ ã�´�.
  ARecursive = false�̸� ���� ������ ã�� �ʴ´�.
}
procedure SearchFolders(APath:string; ARecursive:boolean; AProcedure:TIterateProcedure);

implementation

procedure SearchFiles(APath:string; ARecursive:boolean; AProcedure:TIterateProcedure);
var
  SearchRec : TSearchRec;
  iSearchResult : integer;
  isDirectory : boolean;
  isNeedStop : boolean;
begin
  if Copy(APath, Length(APath), 1) <> '\' then APath := APath + '\';

  isNeedStop := false;

  iSearchResult := FindFirst(APath + '*.*', faAnyFile, SearchRec);
  while iSearchResult = 0 do begin
    // ���丮 �� �����ؾ��� �͵�
    if (SearchRec.Name = '.' ) or (SearchRec.Name = '..') then begin
      iSearchResult := FindNext(SearchRec);
      Continue;
    end;

    isDirectory := (SearchRec.Attr and faDirectory) = faDirectory;

    if isDirectory then begin
      if ARecursive then
        SearchFiles(APath + SearchRec.Name + '\', ARecursive, AProcedure);
    end else begin
      AProcedure(APath, SearchRec, isNeedStop);
      if isNeedStop then Break;
    end;

    iSearchResult:= FindNext(SearchRec);
  end;

  FindClose(SearchRec);
end;

procedure SearchFolders(APath:string; ARecursive:boolean; AProcedure:TIterateProcedure);
var
  SearchRec : TSearchRec;
  iSearchResult : integer;
  isDirectory : boolean;
  isNeedStop : boolean;
begin
  if Copy(APath, Length(APath), 1) <> '\' then APath := APath + '\';

  isNeedStop := false;

  iSearchResult := FindFirst(APath + '*.*', faAnyFile, SearchRec);
  while iSearchResult = 0 do begin
    // ���丮 �� �����ؾ��� �͵�
    if (SearchRec.Name = '.' ) or (SearchRec.Name = '..') then begin
      iSearchResult := FindNext(SearchRec);
      Continue;
    end;

    isDirectory := (SearchRec.Attr and faDirectory) = faDirectory;

    if isDirectory then begin
      AProcedure(APath, SearchRec, isNeedStop);

      if isNeedStop then Break;

      if ARecursive then
        SearchFolders(APath + SearchRec.Name + '\', ARecursive, AProcedure);
    end;

    iSearchResult:= FindNext(SearchRec);
  end;

  FindClose(SearchRec);
end;

end.
