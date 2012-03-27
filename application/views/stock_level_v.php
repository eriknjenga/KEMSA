<?php $this->load->helper('url');?>
<div align="center">
	<script>
	$(function() {
		$("#accordion").accordion({
			autoHeight : false,
			active: false,
			collapsible: true
		});		
		$('#counties').click(function(){
			/*
			 * when clicked, this object should populate district names to district dropdown list.
			 * Initially it sets default values to the 2 drop down lists(districts and facilities) 
			 * then ajax is used is to retrieve the district names using the 'dropdown()' method that has
			 * 3 arguments(the ajax url, value POSTed and the id of the object to populated)
			 */
			$("#districts").html("<option>--disticts--</option>");
			$("#facilities").html("<option>--facilities--</option>");
			json_obj={"url":"<?php echo site_url("order_management/getDistrict");?>",}
			var baseUrl=json_obj.url;
			var id=$(this).attr("value")
			dropdown(baseUrl,"county="+id,"#districts")
		});
		$('#districts').click(function(){
			/*
			 * when clicked, this object should populate facility names to facility dropdown list.
			 * Initially it sets a default value to the facility drop down list then ajax is used 
			 * is to retrieve the district names using the 'dropdown()' method used above.
			 */
			$("#facilities").html("<option>--facilities--</option>");
			json_obj={"url":"<?php echo site_url("order_management/getFacilities");?>",}
			var baseUrl=json_obj.url;
			var id=$(this).attr("value")
			dropdown(baseUrl,"district="+id,"#facilities")
		});
		$('#filter').click(function(){
			
		});
		function dropdown(baseUrl,post,identifier){
			/*
			 * ajax is used here to retrieve values from the server side and set them in dropdown list.
			 * the 'baseUrl' is the target ajax url, 'post' contains the a POST varible with data and
			 * 'identifier' is the id of the dropdown list to be populated by values from the server side
			 */
			$.ajax({
			  type: "POST",
			  url: baseUrl,
			  data: post,
			  success: function(msg){
			  		var values=msg.split("_")
			  		var dropdown;
			  		for (var i=0; i < values.length-1; i++) {
			  			var id_value=values[i].split("*")
			  			dropdown+="<option value="+id_value[0]+">";
						dropdown+=id_value[1];
						dropdown+="</option>";
					};
					$(identifier).html(dropdown);
			  },
			  error: function(XMLHttpRequest, textStatus, errorThrown) {
			       if(textStatus == 'timeout') {}
			   }
			}).done(function( msg ) {
			});
		}
	});
	</script>
	<style>
		td {
			padding: 5px;
		}
		select{
			width: 200px;
		}
	</style>
	<select id="counties">
		<option>--counties--</option>
		<?php 
		foreach ($counties as $counties) {
			$id=$counties->id;
			$county=$counties->county;?>
			<option value="<?php echo $id;?>"><?php echo $county;?></option>
		<?php }
		?>
	</select>
	<select id="districts">
		<option>--disticts--</option>
	</select>
	<select id="facilities">
		<option>--facilities--</option>
	</select>
	<input type="button" id="filter" value="filter" class="button"/>
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
						<td><b>KEMSA Code</b></td><td><b>Description</b></td><td><b>Stock Balance</b></td>
					</tr>
					<?php
						foreach($category->Category_Drugs as $drug){?>
						<tr>
							<td><?php echo $drug->Kemsa_Code;?></td><td><?php echo $drug->Drug_Name;?></td><td><input type="text"  value="0" /></td>
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
			<td><b> Total Stock Balance</b></td><td><b> 20000 </b></td>
		</tr> 
	</table>
	<input class="button" value="Save Order" />
</div><!-- End demo -->

