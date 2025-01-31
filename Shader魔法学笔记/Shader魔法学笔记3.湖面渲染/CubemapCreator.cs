using System.IO;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.Rendering;

namespace DefaultNamespace
{
    public class CubemapCreator : MonoBehaviour
    {
        [MenuItem("Tools/CreateCubemap")]
        static void CreateCubeMapDefault()
        {
            CreateCubemap(Vector3.zero, 1024, "Assets/", "DefaultCubemap");
        } 
        
        static void CreateCubemap(Vector3 position,int width,string path,string name){
            /* create a gameobejct at target position
            and initialize a crmera C, create a cubemap through
            C's RenderToCubemap Function */

            Cubemap _cubemap = new Cubemap(width,DefaultFormat.LDR, TextureCreationFlags.None);
            GameObject _current = new GameObject();
            _current.transform.position = position;
            _current.AddComponent<Camera>();
            if(_current.GetComponent<Camera>().RenderToCubemap(_cubemap)){
                Debug.Log("generate successfully");
                GameObject.DestroyImmediate(_current);
                if(Directory.Exists(path)){
                    AssetDatabase.CreateAsset(_cubemap,$"{path}{name}.cubemap");
                }else{
                    Directory.CreateDirectory(path);
                    AssetDatabase.CreateAsset(_cubemap,$"{path}{name}.cubemap");
                }
                AssetDatabase.SaveAssets();
            }else{
                Debug.Log("generate failed");
            }

        }
    }
}