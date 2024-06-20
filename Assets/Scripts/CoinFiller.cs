using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CoinFiller : MonoBehaviour
{
    private int _totalAmount = 1000;
    public GameObject Coin_prefab;
    private List<GameObject> _coinList = new List<GameObject>();
    public Transform SpawnPoint;

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space)) 
        {
            StartCoroutine(FillCoin());
        }
    }
    IEnumerator FillCoin() 
    {
        int amount = 0;

        for (int i = 0; i < 100; i++)
        {
            GameObject newCoin = Instantiate(Coin_prefab);
            newCoin.transform.position = SpawnPoint.position;
            _coinList.Add(newCoin);
        }
        while (amount < _totalAmount) 
        {
            GameObject newCoin = Instantiate(Coin_prefab);
            newCoin.transform.position = SpawnPoint.position;
            _coinList.Add(newCoin);

            amount += 1;
            yield return null;
      
        }
    }
}
