unit Snappy;

interface

uses
  Windows, SysUtils, Classes;

type
  TSnappyStatus = (
    SNAPPY_OK = 0,
    SNAPPY_INVALID_INPUT = 1,
    SNAPPY_BUFFER_TOO_SMALL = 2
  );

{*
   �־��� �����͸� �����Ѵ�.
   @param input ���� �� �������� ������
   @param input_length ���� �� �������� ũ��
   @param compressed ���� ��� �����͸� ���� �� ������ ������
   @param output_length ���� ����� ���� �� ������ ũ���̴�.  ���� �Ŀ��� ���� �� �������� ũ�Ⱑ ���� �ȴ�.

   - Example:
     output_length := max_compressed_length(input_length);
     GetMem( output, output_length );
     if compress(input, input_length, output, output_length) <> SNAPPY_OK then
       raise Exception.Create('Error');
     ...
     FreeMem( output );
}
function compress(input:pointer; input_length:DWord; compressed:pointer; var compressed_length:DWord):TSnappyStatus; cdecl;
         external 'snappy.dll' delayed;

{*
   ���� �� �������� ������ �����Ѵ�.
   @param compressed ���� �� �������� ������
   @param compressed_length ���� �� �������� ũ��
   @param uncompressed ���� ���� ��� �����͸� ���� �� ������ ������
   @param uncompressed_length ���� ���� ��� �����͸� ���� �� ������ ũ��

   - Example:
    if uncompressed_length(compressed, compressed_length, uncompressed_length) <> SNAPPY_OK then
       raise Exception.Create('Error');
    GetMem( uncompressed, uncompressed_length);
    uncompress(compressed, compressed_length, uncompressed, uncompressed_length) <> SNAPPY_OK then
       raise Exception.Create('Error');
     ...
     FreeMem( uncompressed );
}
function uncompress(compressed:pointer; compressed_length:DWord; uncompressed:pointer; var uncompressed_length:DWord):TSnappyStatus; cdecl;
         external 'snappy.dll' delayed;

function max_compressed_length(source_length:DWord):DWord; cdecl;
         external 'snappy.dll' delayed;

function uncompressed_length(compressed:pointer; compressed_length:DWord; var result_length:DWord):TSnappyStatus; cdecl;
         external 'snappy.dll' delayed;

function  validate_compressed_buffer(compressed:pointer; compressed_length:DWord):TSnappyStatus; cdecl;
         external 'snappy.dll' delayed;

implementation

end.
