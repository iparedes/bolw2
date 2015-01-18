
class Item
	attr_accessor :titulo, :title, :texto, :text, :enlace, :link, :tipo, :tags, :lan, :len, :destacado
	
	def initialize()
		@titulo=nil
		@title=nil
		@texto=nil
		@text=nil
		@enlace=nil
		@link=nil
		@tipo=nil
		@tags=nil
		@lan=nil
		@len=nil
		@destacado=nil
	end

	def setall(titulo,title,texto,text,enlace,link,tipo,tags,lan,len,destacado)
		@titulo=titulo
		@title=title
		@texto=texto
		@text=text
		@enlace=enlace
		@link=link
		@tipo=tipo
		@tags=tags
		@lan=lan
		@len=len
		@destacado=destacado	
	end


	def setfromxml(nodes,noden)
	  # hack tremendo para evitar cuando uno de los nodos es nil
	  # (debido a que los XML no son coherentes
	  begin
		@tipo=(nodes/'./tipo').text	
		@titulo=(nodes/'./titulo').text	
		@title=(noden/'./titulo').text
		if (@tipo=='reflexion') and (@titulo.empty?)
			#settings.nreflex=settings.nreflex+1
			#@titulo="Reflexion "+settings.nreflex
			#@title="Thought "+settings.nreflex
			@titulo="Reflexion"
			@title="Thought"
		end
		@texto=(nodes/'./texto').text	
		@text=(noden/'./texto').text
		@enlace=(nodes/'./link').text	
		@link=(noden/'./link').text
		@tipo=(nodes/'./tipo').text	
		@tags=(noden/'./tag').text
		@len=(nodes/'./lan').text
		@lan=(noden/'./lan').text
		d=(nodes/'./destacado').text
		if d==''
			@destacado=0
		else
			@destacado=d
		end
	  rescue
	  end

	end

end