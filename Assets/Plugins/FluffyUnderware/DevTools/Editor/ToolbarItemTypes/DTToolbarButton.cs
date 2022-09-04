// =====================================================================
// Copyright 2013-2017 Fluffy Underware
// All rights reserved
// 
// http://www.fluffyunderware.com
// =====================================================================

using UnityEngine;
using UnityEditor;


public class DTToolbarButton : DTToolbarItem
{
    public override void Render(Rect r)
    {
        if (GUI.Button(r, Content, DTStyles.TBButton))
            OnClick();
    }
}