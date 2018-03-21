### Refund

To get your funds back from failed crowdsale, user, as crowdsale participant,
 should send another transaction to crowdsale contract address, that user
 used to participate in crowdsale.
  
The transaction has to contain special data field, with signature of refund function.
The signature looks like: `0x590e1ae3`

Execution of function requires crowdsale in failed state or stopped.

Let's try on mew/parity example.

##### Refund via MEW

**Important**: all parameters in next text/screenshots, like addresses, value, other tx settings (excluding data), are 
examples, don't use them on real network.

Steps:

1. Go to **Send Ether & Tokens** page
2. Access your wallet
3. Prepare transaction:
    - **To Address** - crowdsale address
    - **Amount To Send** - 0
    - **Gas Limit** - 100000
4. Click on **Advanced: Add Data**
5. Add next code to **Data** field - `0x590e1ae3`
6. Send transaction

Once transaction confirmed, user will get his ETH back.

For example, look at next screenshot:

![MEW Refund](https://i.imgur.com/C8wBGae.png)

#### Refund via Parity

1. Go to **Accounts** page
2. Choose account that you used to participate in crowdsale
3. Click on 'Transfer' button
4. Fill **the recipient address** with crowdsale contract address
5. Set **amount to transfer** to 0
6. Check **advanced sending options** and click **Next** button
7. On next page fill **transaction data** with `0x590e1ae3`
8. Set **gas** to 100000
9. Send transaction and confirm
