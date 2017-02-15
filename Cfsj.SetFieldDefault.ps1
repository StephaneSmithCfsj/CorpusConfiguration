get-spweb $urlmdd                                                                                               
$w= get-spweb $urlmdd                                                                                           
$l = $w.GetListfromurl("/MDD/Lists/LiensMDD/AllItems.aspx")                        
$f = $l.Fields["Secteur d'activité"]                                                                            
$f.DefaultValue = "-1;#Technologies de l?information|47b2d2aa-8d77-4f8c-bace-80a4b9ec21c4"                         
$f.Update()                                                                                                     
<# obtain list of terms.
$session = New-Object Microsoft.SharePoint.Taxonomy.TaxonomySession($site) 
$termStore = $session.TermStores[0] 
$group = $termStore.Groups["Banque de termes - CFSJ"] 
$termSet = $group.TermSets["Secteur d'activité"] 
$terms = $termSet.GetAllTerms() 
$term = $terms | ?{$_.Name –eq “Corporation”}
#>