using System.Collections;
using UnityEngine;

public class GameContextManager : SingletonBehaviour<GameContextManager>
{
    public Transform playerBody;

    override protected void Awake()
    {
        base.Awake();

        Game.Player = new Player(playerBody);
    }
}