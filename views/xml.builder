xml.boletin do
	xml.id id
	xml.fecha fecha
	
	listas.each do |a|
		a.each do |h|
		
			i=items[h]	

			if lan=='es'
				titulo=i.titulo
				texto=i.texto
				link=i.enlace
			else
				titulo=i.title
				texto=i.text
				link=i.link
			end	

			xml.item do
				xml.titulo titulo
				xml.texto texto
				xml.link link
				xml.tipo i.tipo
				xml.tag i.tags
			end
		end
	end


end


