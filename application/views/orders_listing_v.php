<script type="text/javascript">
	$(function() {

		// Accordion
		$("#accordion").accordion({
			header : "h3"
		});
		//tabs
		$('#tabs').tabs();
	});

</script>
<div id="tabs">
	<!--tabs!-->
	<ul>
		<li>
			<a href="#tabs-1">Pending Review</a>
		</li>
		<li>
			<a href="#tabs-2">Received at Kemsa</a>
		</li>
		<li>
			<a href="#tabs-3">Rejected</a>
		</li>
		<li>
			<a href="#tabs-4">Dispatched</a>
		</li>
	</ul>
	<div id="tabs-1">
		<!--tab1 content!-->
		<table class="data-table">
			<tr>
				<th><strong>Order Number </strong></th>
				<th><strong>Order Made on </strong></th> 
				<th><strong>Days Pending </strong></th> 
				<th>Action</th>
			</tr>
			<tr>
				<td>2UN95BCHGZ</td>
				<td>7/24/2011</td> 
				<td>5</td> 
				<td><a href="#" class="link">View Details</a></td>
			</tr>
			<tr>
				<td>5XZ4C2MTAB</td>
				<td>8/28/2011</td>
				<td>8</td> 
				<td><a href="#" class="link">View Details</a></td>
			</tr>
			<tr>
				<td> 5ZAWTFRCVJ </td>
				<td>9/12/2011</td>
				<td>10</td> 
				<td><a href="#" class="link">View Details</a></td>
			</tr>
			<tr>
				<td> 7SKY2H3LM1 </td>
				<td>10/20/2011</td>
				<td>14</td> 
			<td><a href="#" class="link">View Details</a></td>
			</tr>
			 
		</table>
		<div class="pagination"></div>
	</div><!--tab1!-->
	<div id="tabs-2">
		<!--tab 2 content!-->
		<table class="data-table">
			<tr>
				<th><strong>Order Number </strong></th>
				<th><strong>Order Made on </strong></th> 
				<th><strong>Order Reviewed on </strong></th> 
				<th>Action</th>
			</tr>
			<tr>
				<td>CC81LD028</td>
				<td>7/24/2011</td> 
				<td>7/26/2011</td> 
				<td><a href="#" class="link">View Details</a></td>
			</tr>
			<tr>
				<td>CC85XT056</td>
				<td>7/28/2011</td>
				<td>7/30/2011</td>
				<td><a href="#" class="link">View Details</a></td>
			</tr>
			<tr>
				<td> CC13BK596 </td>
				<td>8/1/2011</td>
				<td>8/4/2011</td>
				<td><a href="#" class="link">View Details</a></td>
			</tr>
		 
		</table>
		<div class="ui-accordion-content"></div>
		<!--tab 2 ui-accordion-content!-->
	</div><!--tab 2 content!-->
	<div id="tabs-3">
		<!--tab 3 content!-->
		<table class="data-table">
			<tr>
				<th><strong>Order Number </strong></th>
				<th><strong>Order Made on </strong></th> 
				<th><strong>Order Rejected on </strong></th> 
				<th>Action</th>
			</tr>
			<tr>
				<td>DC82LD028</td>
				<td>7/24/2011</td> 
				<td>7/26/2011</td> 
				<td><a href="#" class="link">View Details</a></td>
			</tr>
			<tr>
				<td>DC85XT056</td>
				<td>7/28/2011</td>
				<td>7/30/2011</td>
				<td><a href="#" class="link">View Details</a></td>
			</tr>
			<tr>
				<td> DC13BK596 </td>
				<td>8/1/2011</td>
				<td>8/4/2011</td>
				<td><a href="#" class="link">View Details</a></td>
			</tr>
		 
		</table>
	</div><!--tab 3!-->
	<div id="tabs-4">
		<!--tab 4 content!-->
		<table class="data-table">
			<tr>
				<th><strong>Order Number </strong></th>
				<th><strong>Order Made on </strong></th> 
				<th><strong>Order Reviewed on </strong></th> 
				<th><strong>Commodities Dispatched on </strong></th> 
				<th>Action</th>
			</tr>
			<tr>
				<td>EC82LD028</td>
				<td>7/24/2011</td> 
				<td>7/26/2011</td> 
				<td>7/30/2011</td>
				<td><a href="#" class="link">View Details</a></td>
			</tr>
			<tr>
				<td>EC85XT056</td>
				<td>7/28/2011</td>
				<td>7/30/2011</td>
				<td>8/1/2011</td>
				<td><a href="#" class="link">View Details</a></td>
			</tr>
			<tr>
				<td>EC13BK596 </td>
				<td>8/1/2011</td>
				<td>8/4/2011</td>
				<td>8/8/2011</td>
				<td><a href="#" class="link">View Details</a></td>
			</tr>
		 
		</table>
	</div><!--tab 3!-->
</div>
<!--tabs!-->