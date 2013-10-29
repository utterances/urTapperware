-- ===============================
-- = Visual Links between regions=
-- ===============================

-- methods and appearances and menus for deleting / editing
-- assumes urTapperwareMenu.lua is already processed

linkLayer = {}

function linkLayer:Init()
	self.list = {}
	-- this is actually a dictionary, key = sender, value = {list of receivers}
	self.potentialLinkList = {}
	
	-- one region for drawing formed links
	self.links = Region('region', 'backdrop', UIParent)
	self.links:SetWidth(ScreenWidth())
	self.links:SetHeight(ScreenHeight())
	self.links:SetLayer("TOOLTIP")
	self.links:SetAnchor('BOTTOMLEFT',0,0)
	self.links.t = self.links:Texture()
	self.links.t:Clear(0,0,0,0)
	self.links.t:SetTexCoord(0,ScreenWidth()/1024.0,1.0,0.0)
	self.links.t:SetBlendMode("BLEND")
	self.links:EnableInput(false)
	self.links:EnableMoving(false)
	
	self.links:MoveToTop()
	self.links:Show()
	self.links.needsDraw=true
	self.links:Handle("OnUpdate", linkLayer.Update)
	self.links.parent = self
	
	-- set up another region for drawing guides or potential links
	self.linkGuides = Region('region', 'backdrop', UIParent)
	self.linkGuides:SetWidth(ScreenWidth())
	self.linkGuides:SetHeight(ScreenHeight())
	self.linkGuides:SetLayer("TOOLTIP")
	self.linkGuides:SetAnchor('BOTTOMLEFT',0,0)
	self.linkGuides.t = self.linkGuides:Texture()
	self.linkGuides.t:Clear(0,0,0,0)
	self.linkGuides.t:SetTexCoord(0,ScreenWidth()/1024.0,1.0,0.0)
	self.linkGuides.t:SetBlendMode("BLEND")
	self.linkGuides:EnableInput(false)
	self.linkGuides:EnableMoving(false)
	
	self.linkGuides:MoveToTop()
	self.linkGuides:Show()
	
end

-- add links to our list
function linkLayer:Add(l)
	for k,v in pairs(self.list) do
		if v == l then
			DPrint("duplicate link found")
			return false;
		end
	end
	-- Not yet in global manager
	
	table.insert(self.list,l)
end

-- remove links
function linkLayer:Remove(l)
	for k,v in pairs(self.list) do
		if v == l then
			table.remove(self.list,k)
			notifyView:ShowTimedText("Removed Link")
			return true
		end
	end
	DPrint("Link not found for removal from global list")
	return false
end

function linkLayer:Update()
	-- draw a line between linked regions, also draws menu
	if self.needsDraw then
		self.needsDraw = false
		self.t:Clear(0,0,0,0)
	
		for _, link in pairs(self.parent.list) do
			X1, Y1 = link.sender:Center()
			X2, Y2 = link.receiver:Center()

			if link.sender.menu ~= nil or link.receiver.menu ~= nil then
				self.t:SetBrushColor(100,120,120,200)
				self.t:SetBrushSize(5)
				self.t:Line(X1,Y1,X2,Y2)
				-- draw the link menu (close button), it will compute centroid using
				-- region locations	
				OpenLinkMenu(link.menu)
			else
				self.t:SetBrushColor(100,120,120,100)
				self.t:SetBrushSize(5)
				self.t:Line(X1,Y1,X2,Y2)
				HideLinkMenu(link.menu)
			end
		end
	end
end

function linkLayer:Draw()
	self.links.needsDraw = true	
end

function linkLayer:DrawPotentialLink(region, draglet)
	self.linkGuides.t:Clear(0,0,0,0)
	self.linkGuides.t:SetBrushColor(195,240,240,150)
	self.linkGuides.t:SetBrushSize(10)
	
	rx, ry = region:Center()
	posx, posy = draglet:Center()
	self.linkGuides.t:Line(rx,ry,posx,posy)
end

function linkLayer:ResetPotentialLink()
	self.linkGuides.t:Clear(0,0,0,0)
end
