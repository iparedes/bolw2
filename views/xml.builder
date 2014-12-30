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
				idioma=i.len
			else
				titulo=i.title
				texto=i.text
				link=i.link
				idioma=i.lan
			end	

			xml.item do
				xml.titulo titulo
				xml.texto texto
				xml.link link
				xml.tipo i.tipo
				xml.tag i.tags
				xml.lan idioma
				xml.destacado i.destacado
			end
		end
	end


end


