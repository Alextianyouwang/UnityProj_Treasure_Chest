using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;
using static UnityEngine.Rendering.HableCurve;

[ExecuteInEditMode]
public class Texcorder : MonoBehaviour
{
    public Camera Cam;
    public GameObject ObjectToCapture;
    public string Name;

    private List<Texture2D> _captureResults = new List<Texture2D>();

    private void OnEnable()
    {
        SequenceCapture(ObjectToCapture.transform.position, 4f, 16);
    }

     void Update()
    {
        //if (Input.GetKeyDown(KeyCode.Space)) 
        //{
        //   StartCoroutine(SequenceCapture(ObjectToCapture.transform.position, 4f, 16,0.15f))  ;
        //}    
    }
    void SequenceCapture(Vector3 center, float radius, int segments) 
    {
        float inc = 2 * Mathf.PI / segments;

        Vector3 initialEuler = ObjectToCapture.transform.eulerAngles;
        Vector3 euler = ObjectToCapture.transform.eulerAngles;
        for (int i = 0; i < segments; i++) 
        {
            float theta = i * inc;

            ObjectToCapture.transform.eulerAngles = new Vector3(euler.x, euler.y + theta * Mathf.Rad2Deg, euler.z);
            RenderContent();
        }

        SaveTexture(CombineTextures(_captureResults.ToArray()), "CaptureData", Name);
        _captureResults.Clear();
        ObjectToCapture.transform.eulerAngles = initialEuler;
    }
    IEnumerator SequenceCapture(Vector3 center, float radius, int segments, float timeBetweenCapture) 
    {
        float inc = 2 * Mathf.PI / segments;

        Vector3 initialEuler = ObjectToCapture.transform.eulerAngles;
        Vector3 euler = ObjectToCapture.transform.eulerAngles;
        for (int i = 0; i < segments; i++)
        {
            float theta = i * inc;

            ObjectToCapture.transform.eulerAngles = new Vector3(euler.x, euler.y + theta * Mathf.Rad2Deg, euler.z);
            RenderContent();
            yield return new WaitForSeconds(timeBetweenCapture) ;
        }

        SaveTexture(CombineTextures(_captureResults.ToArray()), "CaptureData", Name);
        _captureResults.Clear();
        ObjectToCapture.transform.eulerAngles = initialEuler;
    }
    void RenderContent() 
    {
        CameraClearFlags tempClearFlag = Cam.clearFlags;
        Cam.clearFlags = CameraClearFlags.SolidColor;
        Cam.backgroundColor = Color.clear; 
        RenderTexture.active = Cam.targetTexture;

        Cam.Render();


        Texture2D image = new Texture2D(Cam.targetTexture.width, Cam.targetTexture.height, TextureFormat.RGBAFloat, false);
        image.ReadPixels(new Rect(0, 0, RenderTexture.active.width, RenderTexture.active.height), 0, 0);
        image.Apply();

        Cam.clearFlags = tempClearFlag;
        _captureResults.Add(image);
    }


    public static Texture2D CombineTextures(Texture2D[] textures)
    {
        if (textures == null || textures.Length == 0)
        {
            Debug.LogError("Texture array is null or empty!");
            return null;
        }

        // Determine the dimensions of the combined texture
        int width = 0;
        int height = 0;

        foreach (var texture in textures)
        {
            if (texture == null)
            {
                Debug.LogError("One of the textures in the array is null!");
                return null;
            }

            width += texture.width;
            height = Mathf.Max(height, texture.height);
        }

        // Create the combined texture
        Texture2D combinedTexture = new Texture2D(width, height, TextureFormat.RGBA32, false);

        // Set the pixels from each texture into the combined texture
        int offsetX = 0;

        foreach (var texture in textures)
        {
            Color[] pixels = texture.GetPixels();
            combinedTexture.SetPixels(offsetX, 0, texture.width, texture.height, pixels);
            offsetX += texture.width;
        }

        // Apply all the SetPixels changes
        combinedTexture.Apply();

        return combinedTexture;
    }

    public void SaveTexture(Texture2D image, string path, string name)
    {
        byte[] bytes = image.EncodeToPNG();
        File.WriteAllBytes(Path.Combine(Application.dataPath, path, name + ".png"), bytes);
        Debug.Log($"Saved camera capture to: {path}");
        AssetDatabase.Refresh();
    }


}
