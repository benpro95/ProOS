 function upload(file) {
            var blob = file;
            var BYTES_PER_CHUNK = 128; 
            var SIZE = file.size;               
            var start = 0;
            var end = BYTES_PER_CHUNK;
            var completed = 0;
            var count = SIZE % BYTES_PER_CHUNK == 0 ? SIZE / BYTES_PER_CHUNK : Math.floor(SIZE / BYTES_PER_CHUNK) + 1;
            var index = 1;
            while (start < SIZE) {
                var chunk = blob.slice(start, end);
                var data = new FormData();
                data.append("TOTAL_CHUNK", count);
                data.append("CHUNK_INDEX", index++);
                data.append("CHUNK", chunk);

                var xhr = new XMLHttpRequest();
                xhr.open("POST", "UploadChunks", true);
                xhr.setRequestHeader("Content-Type", "multipart/form-data");
                xhr.send(data);

               /* fetch("/UploadFile/MultiUpload", {
                    method: 'post',
                    body: data
                });*/
                   
                start = end
                end = start + BYTES_PER_CHUNK;
            }   
        }     


 [HttpPost]
    public string MultiUpload()
    {
        var chunks = Request.InputStream;

        string path = Server.MapPath("~/tmp");
        string newpath = Path.Combine(path, Path.GetRandomFileName());

        using (System.IO.FileStream fs = System.IO.File.Create(newpath))
        {
            byte[] bytes = new byte[77570];

            int bytesRead;
            while ((bytesRead = Request.InputStream.Read(bytes, 0, bytes.Length)) > 0)
            {
                fs.Write(bytes, 0, bytesRead);
            }
        }
        return "test";
    }

    [HttpPost]
    public string UploadComplete(string fileName, bool completed)
    {
        if (completed)
        {
            string path = Server.MapPath("~/App_Data/Uploads/Tamp");
            string newpath = Path.Combine(path, fileName);
            string[] filePaths = Directory.GetFiles(path);

            foreach (string item in filePaths)
            {
                MergeFiles(newpath, item);
            }
        }
        return "success";
    }

    private static void MergeFiles(string file1, string file2)
    {
        FileStream fs1 = null;
        FileStream fs2 = null;
        try
        {
            fs1 = System.IO.File.Open(file1, FileMode.Append);
            fs2 = System.IO.File.Open(file2, FileMode.Open);
            byte[] fs2Content = new byte[fs2.Length];
            fs2.Read(fs2Content, 0, (int)fs2.Length);
            fs1.Write(fs2Content, 0, (int)fs2.Length);
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.Message + " : " + ex.StackTrace);
        }
        finally
        {
            fs1.Close();
            fs2.Close();
            System.IO.File.Delete(file2);
        }
    }




foreach (Images item in ListOfImages)
{
    using (System.IO.FileStream output = new System.IO.FileStream(Path.Combine(newPath, item.ImageName + item.ImageExtension),
        System.IO.FileMode.Create, System.IO.FileAccess.Write))
    {
        output.Write(item.File, 0, item.File.Length);
        output.Flush();
        output.Close();
    }
}


GC.Collect();