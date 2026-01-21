public void SynchronousMethod()
{
    // ... some synchronous work ...

    // Use this to run an async method from a sync context safely
    string result = Task.Run(() => Async("test")).GetAwaiter().GetResult();

    // ... use the result ...
}

public async Task<string> Async(string input)
{
    await Task.Delay(1000); // Simulate I/O-bound work
    return "Generated Code: " + input;
}

using Azure.Storage.Blobs;
using System;
using System.IO;
using System.IO.Compression;
using System.Threading.Tasks;

public static async Task UnzipBlobAsync(string zipBlobConnectionString, string containerName, string zipFileName, string outputContainerName)
{
    // Initialize Blob Service Client
    BlobServiceClient blobServiceClient = new BlobServiceClient(zipBlobConnectionString);
    BlobContainerClient containerClient = blobServiceClient.GetBlobContainerClient(containerName);
    BlobClient zipBlobClient = containerClient.GetBlobClient(zipFileName);

    BlobContainerClient outputContainerClient = blobServiceClient.GetBlobContainerClient(outputContainerName);
    await outputContainerClient.CreateIfNotExistsAsync();

    // Use a MemoryStream (or a temporary local file for very large zips) to hold the blob content
    using (var zipBlobFileStream = new MemoryStream())
    {
        // Download the zip file content into the stream
        await zipBlobClient.DownloadToStreamAsync(zipBlobFileStream);
        
        // Reset the stream position to the beginning after downloading
        zipBlobFileStream.Position = 0;

        // Use ZipArchive from System.IO.Compression to extract all the files from the zip file
        using (var archive = new ZipArchive(zipBlobFileStream, ZipArchiveMode.Read))
        {
            // Each entry represents an individual file or a folder within the zip
            foreach (var entry in archive.Entries)
            {
                // Skip empty entries which usually represent folders
                if (entry.Length == 0) continue;

                // Create a new blob client for the extracted file in the output container
                BlobClient outputBlobClient = outputContainerClient.GetBlobClient(entry.FullName);

                // Open the entry stream and upload it to the new blob
                using (var entryStream = entry.Open())
                {
                    await outputBlobClient.UploadAsync(entryStream, overwrite: true);
                }
            }
        }
    }
    Console.WriteLine($"Successfully unzipped {zipFileName} to container {outputContainerName}");
}

static void Main(string[] args)
{
    var cloudStorageAccount = CloudStorageAccount.Parse(@"<connection_string_here>");

    var sourceContainer = "container1";
    var destinationContainer = "container2";
    var sourceFilename = "picture.jpg";
    var destinationFilename = "picture_in_container_2.jpg";

    var copyResult = CopyBlob(cloudStorageAccount, sourceContainer, destinationContainer, sourceFilename, destinationFilename);

    if (copyResult.Status == CopyStatus.Success)
    {
        DeleteBlob(cloudStorageAccount, sourceContainer, sourceFilename);
    }
}

private static CopyState CopyBlob(CloudStorageAccount cloudStorageAccount, string sourceContainerName, string destinationContainerName, string sourceFileName, string destinationFileName)
{
    var blobStorageClient = cloudStorageAccount.CreateCloudBlobClient();

    var sourceContainer = blobStorageClient.GetContainerReference(sourceContainerName);
    var destinationContainer = blobStorageClient.GetContainerReference(destinationContainerName);

    var sourceBlob = sourceContainer.GetBlobReference(sourceFileName);

    var destinationBlob = destinationContainer.GetBlobReference(destinationFileName);

    var result = destinationBlob.StartCopy(sourceBlob.Uri);

    var copyResult = destinationBlob.CopyState;

    return copyResult;
}

private static void DeleteBlob(CloudStorageAccount cloudStorageAccount, string containerName, string blobFileName)
{
    var blobStorageClient = cloudStorageAccount.CreateCloudBlobClient();
    var container = blobStorageClient.GetContainerReference(containerName);
    var blob = container.GetBlobReference(blobFileName);
    blob.Delete();
}

public class GraphMailService
{
    private readonly IConfiguration _config;

    public GraphMailService(IConfiguration config)
    {
        _config = config;
    }

    public async Task SendAsync(string fromAddress, string toAddress, string subject, string content)
    {
        string? tenantId = _config["tenantId"];
        string? clientId = _config["clientId"];
        string? clientSecret = _config["clientSecret"];

        ClientSecretCredential credential = new(tenantId, clientId, clientSecret);
        GraphServiceClient graphClient = new(credential);

        Message message = new()
        {
            Subject = subject,
            Body = new ItemBody
            {
                ContentType = BodyType.Text,
                Content = content
            },
            ToRecipients = new List<Recipient>()
            {
                new Recipient
                {
                    EmailAddress = new EmailAddress
                    {
                        Address = toAddress
                    }
                }
            }
        };

        bool saveToSentItems = true;

        await graphClient.Users[fromAddress]
          .SendMail(message, saveToSentItems)
          .Request()
          .PostAsync();
    }
}




Source - https://stackoverflow.com/a
// Posted by Ikhtesam Afrin
// Retrieved 2026-01-16, License - CC BY-SA 4.0

using Microsoft.Graph;
using Azure.Identity;
using Microsoft.Graph.Models;
using Microsoft.Graph.Users.Item.SendMail;

var scopes = new[] { "https://graph.microsoft.com/.default" };

var tenantId = "{tenant_id}";

// Values from app registration
var clientId = "{client_id}";
var clientSecret = "{client_Secret}";

// using Azure.Identity;
var options = new TokenCredentialOptions
{
    AuthorityHost = AzureAuthorityHosts.AzurePublicCloud
};

var clientSecretCredential = new ClientSecretCredential(
    tenantId, clientId, clientSecret, options);

var accessToken = await clientSecretCredential.GetTokenAsync(new Azure.Core.TokenRequestContext(scopes) { });
var graphClient = new GraphServiceClient(clientSecretCredential, scopes);
var requestBody = new SendMailPostRequestBody
{
    Message = new Message
    {
        Subject = "Meet for lunch?",
        Body = new ItemBody
        {
            ContentType = BodyType.Text,
            Content = "The new cafeteria is open.",
        },
        ToRecipients = new List<Recipient>
        {
            new Recipient
            {
                EmailAddress = new EmailAddress
                {
                    Address = "{Recipient email address}",
                },
            },
        },
    },
    SaveToSentItems = true,
};

await graphClient.Users["*****@*****.onmicrosoft.com"].SendMail.PostAsync(requestBody);