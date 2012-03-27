<?php $this->load->helper('url');?>
<script>
	json_obj = {
				"url" : "<?php echo base_url().'Images/calendar.gif';?>",
				};
	var baseUrl=json_obj.url;
	
	$(function() {
		$("#accordion").accordion({
			autoHeight : false,
			collapsible: true,
			active: false
		});
		$( "#datepicker" ).datepicker({
			showOn: "button",
			dateFormat: 'yy-mm-dd', 
			buttonImage: baseUrl,
			buttonImageOnly: true
		});
	});

</script>
<style>
	td {
		padding: 5px;
	}
</style>
<div align="center">
	<table>
		<tr>
			<td>Service Point</td>
			<td>
				<select>
					<option>OPD</option> 
					<option>MCH</option> 
					<option>FP/RH Clinic</option> 
					<option>Maternity</option> 
					<option>CCC</option> 
					<option>Female Ward</option> 
					<option>Male Ward</option> 
					<option>Paediatric Ward</option> 
					<option>Laboratory</option> 
					<option>Other</option> 
				</select>
			</td>
		
			<td>S11 No</td>
			<td>
				<input type="text" placeholder="enter a numerical value" />
			</td>
			<td>Date of issue</td>
			<td>			 
				<?php 
					$this->load->helper('date');
					$today= standard_date('DATE_ATOM', time()); //get today's date in full
					$today=substr($today,0,9); //get the YYYY-MM-dd format of the date above								
				?>
				<input type="text" readonly="readonly" value="<?php echo $today;?>" id="datepicker"/>			
			</td>
		</tr>
	</table>
</div>

<div class="demo" style="margin: 10px;">
	<div id="accordion">
		<?php
		foreach($drug_categories as $category){?>
			<h3><a href="#"><?php echo $category->Category_Name?></a></h3>
			<div>
			<p>
				<table>
					<tr>
						<td><b>KEMSA Code</b></td><td><b>Description</b></td><td><b>Stock Balance</b></td><td><b>Quantity Issued</b></td>
					</tr>
					<?php
						foreach($category->Category_Drugs as $drug){?>
						<tr>
							<td><?php echo $drug->Kemsa_Code;?></td><td><?php echo $drug->Drug_Name;?></td><td> <?php echo $drug->Unit_Size;?> </td><td><input type="text"  value="0" /></td>
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
			<td><b> Total Drugs Issued</b></td><td><b>10000 </b></td>
		</tr>
	</table>
	<input class="button" value="Save Issue" />
</div><!-- End demo -->