
class Item
	attr_accessor :titulo, :title, :texto, :text, :enlace, :link, :tipo, :tags, :idioma
	
	def initialize()
		@titulo=nil
		@title=nil
		@texto=nil
		@text=nil
		@enlace=nil
		@link=nil
		@tipo=nil
		@tags=nil
		@idioma=nil
	end

	def setall(titulo,title,texto,text,enlace,link,tipo,tags,idioma)
		@titulo=titulo
		@title=title
		@texto=texto
		@text=text
		@enlace=enlace
		@link=link
		@tipo=tipo
		@tags=tags
		@idioma=idioma		
	end


	def setfromxml(nodes,noden)
		@tipo=(nodes/'./tipo').text	
		@titulo=(nodes/'./titulo').text	
		@title=(noden/'./titulo').text
		if (@tipo=='reflexion') and (@titulo.empty?)
			settings.nreflex=settings.nreflex+1
			@titulo="Reflexion "+settings.nreflex
			@title="Thought "+settings.nreflex
		end
		@texto=(nodes/'./texto').text	
		@text=(noden/'./texto').text
		@enlace=(nodes/'./link').text	
		@link=(noden/'./link').text
		@tipo=(nodes/'./tipo').text	
		@tags=(noden/'./tag').text
		@idioma=(nodes/'./idioma').text
	end

end