using FTemplateNamespace;
using UnityEngine;

public sealed class FTemplateSetup : MonoBehaviour
{
    private const string DEFAULT_GALLERY_CONFIG_NAME = "Default Gallery Config";
    private const string DEFAULT_ADS_CONFIG_NAME = "Default Ads Config";
    private const string DEFAULT_SHOP_CONFIG_NAME = "Default Shop Config";

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    public static void Setup()
    {
        GalleryConfiguration galleryConfig = Resources.Load(DEFAULT_GALLERY_CONFIG_NAME) as GalleryConfiguration;
        if (galleryConfig) FTemplate.Gallery.SetConfiguration(galleryConfig);

        AdsConfiguration adsConfig = Resources.Load(DEFAULT_ADS_CONFIG_NAME) as AdsConfiguration;
        if (adsConfig) FTemplate.Ads.SetConfiguration(adsConfig);

        ShopConfiguration shopConfig = Resources.Load(DEFAULT_SHOP_CONFIG_NAME) as ShopConfiguration;
        if (shopConfig) FTemplate.Shop.SetConfiguration(shopConfig);
    }
}