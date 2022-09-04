using TMPro;
using UnityEngine;

namespace FTemplateNamespace
{
	// Credit: https://catlikecoding.com/unity/tutorials/frames-per-second/
	public class FPSDisplay : MonoBehaviour
	{
#pragma warning disable 0649
		[System.Serializable]
		private struct FPSColor
		{
			public Color Color;
			public int MinimumFPS;
		}

		[SerializeField] private FPSColor[] fpsColors;
#pragma warning restore 0649

		private readonly string[] fpsLabels =
		{
			"00", "01", "02", "03", "04", "05", "06", "07", "08", "09",
			"10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
			"20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
			"30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
			"40", "41", "42", "43", "44", "45", "46", "47", "48", "49",
			"50", "51", "52", "53", "54", "55", "56", "57", "58", "59",
			"60", "61", "62", "63", "64", "65", "66", "67", "68", "69",
			"70", "71", "72", "73", "74", "75", "76", "77", "78", "79",
			"80", "81", "82", "83", "84", "85", "86", "87", "88", "89",
			"90", "91", "92", "93", "94", "95", "96", "97", "98", "99"
		};

		private TextMeshProUGUI fpsText;

		private readonly int[] fpsBuffer = new int[60];
		private int fpsBufferIndex = 0;

		private void Awake()
		{
			fpsText = GetComponent<TextMeshProUGUI>();
		}

		private void Update()
		{
			fpsBuffer[fpsBufferIndex++] = (int) ( 1f / Time.unscaledDeltaTime );

			if( fpsBufferIndex >= fpsBuffer.Length )
				fpsBufferIndex = 0;

			int averageFPS = 0;
			for( int i = 0; i < fpsBuffer.Length; i++ )
			{
				int fps = fpsBuffer[i];
				averageFPS += fps;
			}

			averageFPS = (int) ( (float) averageFPS / fpsBuffer.Length );

			fpsText.text = fpsLabels[Mathf.Clamp( averageFPS, 0, 99 )];
			for( int i = fpsColors.Length - 1; i >= 0; i-- )
			{
				if( averageFPS >= fpsColors[i].MinimumFPS )
				{
					fpsText.color = fpsColors[i].Color;
					break;
				}
			}
		}
	}
}