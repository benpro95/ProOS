using Azure.Storage.Blobs;
using System.IO;
using System.Threading.Tasks;

public static async Task DownloadBlobFromStreamAsync(BlobClient blobClient, string localFilePath)
{
    // Open a stream to the blob using OpenReadAsync()
    using (var stream = await blobClient.OpenReadAsync())
    {
        // Create a FileStream to write the data to a local file
        using (FileStream fileStream = File.OpenWrite(localFilePath))
        {
            // Copy the blob stream to the file stream asynchronously
            await stream.CopyToAsync(fileStream);
        }
    }
}

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