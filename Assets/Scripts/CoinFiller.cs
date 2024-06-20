using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CoinFiller : MonoBehaviour
{
    private int _totalAmount = 300;
    public GameObject Coin_prefab;
    private List<GameObject> _coinList = new List<GameObject>();
    public Transform SpawnPoint;

    public void StartFillCoin() 
    {
        StartCoroutine(FillCoin());
    }
    IEnumerator FillCoin() 
    {
        int amount = 0;

        for (int i = 0; i < 100; i++)
        {
            GameObject newCoin = Instantiate(Coin_prefab, SpawnPoint.position + new Vector3 (Random.Range (-1f,1f), 0, Random.Range(-1f,1f)), Quaternion.identity);
            _coinList.Add(newCoin);
        }
        while (amount < _totalAmount) 
        {
            GameObject newCoin = Instantiate(Coin_prefab, SpawnPoint.position + new Vector3(Random.Range(-1f, 1f), 0, Random.Range(-1f, 1f)), Quaternion.identity);
            _coinList.Add(newCoin);

            amount += 1;
            yield return null;
      
        }
        for (int i = 0; i < 100; i++)
        {
            GameObject newCoin = Instantiate(Coin_prefab, SpawnPoint.position + new Vector3(Random.Range(-1f, 1f), 0, Random.Range(-1f, 1f)), Quaternion.identity);
            _coinList.Add(newCoin);
        }
    }
}
