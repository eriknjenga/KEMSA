<style>
	td {
		padding: 5px;
	}
</style>
<form>
	<table style="margin: 5px auto; border: 2px solid #036; font-size:14px;">
		<tr>
			<td><b>Order Number:</b></td><td> CC86QR864 </td>
			<td><b>Total Value:</b></td><td> 78000 </td>
			<td><b>Order Made on: </b></td>
			<td> 3/10/2012 </td>
			<td><b>Order Dispatched on: </b></td>
			<td> 3/12/2012 </td>
		</tr>
	</table>
	<table style="margin:0 auto">
		<tr>
			<td><label for="delivery_date">Delivery Date</label></td>
			<td>
			<input type="text" />
			</td>
		</tr>
		<tr>
			<td><label for="delivery_note">Delivery Note Number</label></td>
			<td>
			<input type="text" />
			</td>
		</tr>
		<tr>
			<td><label for="commodity_batch">Commodity Batch Number</label></td>
			<td>
			<input type="text" />
			</td>
		</tr>
	</table>
	<table class="data-table">
		<caption>
			<b>Ordered vs. Delivered Quantities</b>
		</caption>
		<tr>
			<th> Commodity </th>
			<th> Order Unit Size </th>
			<th> Ordered Quantity </th>
			<th> Delivered Quantity </th>
		</tr>
		<tr>
			<td>Acyclovir Tablets 400mg</td>
			<td> 100 </td>
			<td> 5000 </td>
			<td>
			<input type="text"   value="">
			</td>
		</tr>
		<tr>
			<td>Albendazole Tablets 400mg</td>
			<td> 1000 </td>
			<td> 30 </td>
			<td>
			<input type="text"   value="">
			</td>
		</tr>
		<tr>
			<td>Amitriptylline Tablets 25mg</td>
			<td> 1000 </td>
			<td> 700 </td>
			<td>
			<input type="text"   value="">
			</td>
		</tr>
	</table>
	<table style="margin:0 auto">
		<tr>
			<td><label for="comments">Remarks:</label></td><td>			<textarea name="comments"></textarea></td>
		</tr>
		<tr>
			<td colspan="2">
			<input class="button" value="Save Delivery Update" />
			</td>
		</tr>
	</table>
</form>