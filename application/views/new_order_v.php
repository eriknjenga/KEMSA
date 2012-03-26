<script>
	$(function() {
		$("#accordion").accordion({
			autoHeight : false,
		});
	});

</script>
<style>
	td {
		padding: 5px;
	}
</style>
<div class="demo" style="margin: 10px;">
	<div id="accordion">
		<?php
		foreach($drug_categories as $category){?>
			<h3><a href="#"><?php echo $category->Category_Name?></a></h3>
			<div>
			<p>
				<table>
					<tr>
						<td><b>KEMSA Code</b></td><td><b>Description</b></td><td><b>Order Unit Size</b></td><td><b>Order Unit Cost</b></td><td><b>Current Balance</b></td><td><b>Quantity Ordered</b></td>
					</tr>
					<?php
						foreach($category->Category_Drugs as $drug){?>
						<tr>
							<td><?php echo $drug->Kemsa_Code;?></td><td><?php echo $drug->Drug_Name;?></td><td> <?php echo $drug->Unit_Size;?> </td><td><?php echo $drug->Unit_Cost;?> </td><td>
							<input type="text"  value="0" />
							</td><td>
							<input type="text"  value="0" />
							</td>
						</tr>
						<?php
						}
					?>
				</table>
			</p>
		</div>
		<?php }
		?>
	</div>
	<table style="font-family: Helvetica, Arial, sans-serif;">
		<tr>
			<td><b> Total Order Value</b></td><td><b> - </b></td>
		</tr>
		<tr>
			<td><b> Drawing Rights Available Balance</b></td><td><b> 6 000 000 </b></td>
		</tr> 
	</table>
	<input class="button" value="Save Order" />
</div><!-- End demo -->