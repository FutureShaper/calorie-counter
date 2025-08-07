#!/usr/bin/env python3
"""
Agentic Food Analysis Workflow

This module provides a complete implementation of an agentic workflow for food analysis,
demonstrating how multiple specialized AI agents can work together to provide comprehensive
nutrition analysis, health recommendations, and meal planning suggestions.

Usage:
    python agentic_food_analysis.py --image path/to/food/image.jpg --api-key your-openai-key

Author: Calorie Counter Team
License: MIT
"""

import asyncio
import json
import base64
import argparse
import sys
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from datetime import datetime
import aiohttp
from PIL import Image
import io


@dataclass
class NutritionData:
    """Comprehensive nutrition information"""
    protein: float  # grams
    carbohydrates: float  # grams
    fats: float  # grams
    fiber: float  # grams
    calories: float  # kcal
    sodium: float  # mg
    sugar: float  # grams
    cholesterol: float  # mg
    vitamin_c: float  # mg
    calcium: float  # mg
    iron: float  # mg


@dataclass
class FoodItem:
    """Identified food item with metadata"""
    name: str
    category: str
    portion_size: str
    confidence: float
    preparation_method: str
    estimated_weight: float  # grams


@dataclass
class HealthRecommendation:
    """Personalized health recommendation"""
    category: str  # e.g., "portion_control", "nutrient_balance", "timing"
    message: str
    priority: str  # "high", "medium", "low"
    reasoning: str


@dataclass
class MealSuggestion:
    """Complementary food suggestion"""
    food_name: str
    category: str
    reason: str
    nutritional_benefit: str


@dataclass
class AnalysisResult:
    """Complete analysis result from all agents"""
    food_items: List[FoodItem]
    nutrition: NutritionData
    health_recommendations: List[HealthRecommendation]
    meal_suggestions: List[MealSuggestion]
    confidence_score: float
    analysis_timestamp: datetime
    agent_coordination_log: List[str]


class BaseAgent:
    """Base class for all agents in the workflow"""
    
    def __init__(self, name: str, api_key: str, model: str = "gpt-4-vision-preview"):
        self.name = name
        self.api_key = api_key
        self.model = model
        self.base_url = "https://api.openai.com/v1/chat/completions"
        self.conversation_history = []
        
    async def call_llm(self, messages: List[Dict], max_tokens: int = 500, temperature: float = 0.1) -> str:
        """Make an async call to the LLM"""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": self.model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(self.base_url, headers=headers, json=payload) as response:
                if response.status == 200:
                    data = await response.json()
                    return data['choices'][0]['message']['content']
                else:
                    error_text = await response.text()
                    raise Exception(f"API call failed with status {response.status}: {error_text}")
    
    def log_action(self, action: str) -> str:
        """Log agent actions for transparency"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        log_entry = f"[{timestamp}] {self.name}: {action}"
        return log_entry


class PlanningAgent(BaseAgent):
    """Agent responsible for analyzing images and creating analysis strategies"""
    
    def __init__(self, api_key: str):
        super().__init__("PlanningAgent", api_key)
    
    async def analyze_image_and_plan(self, image_base64: str) -> Dict[str, Any]:
        """Analyze the food image and create an analysis plan"""
        
        prompt = """
        You are a Planning Agent for food analysis. Examine this image and create a comprehensive analysis plan.
        
        Identify:
        1. All visible food items
        2. Portion sizes and serving estimates
        3. Preparation methods (grilled, fried, raw, etc.)
        4. Food categories (protein, vegetables, grains, etc.)
        5. Complexity level (simple single item vs. complex meal)
        6. Special considerations (dietary restrictions, allergens)
        
        Return a JSON object with your analysis plan:
        {
            "food_items": [
                {
                    "name": "item_name",
                    "category": "category",
                    "estimated_weight": weight_in_grams,
                    "preparation": "method",
                    "confidence": confidence_score
                }
            ],
            "complexity": "simple|moderate|complex",
            "analysis_focus": ["nutrition", "health", "meal_planning"],
            "special_considerations": ["allergen_info", "dietary_restrictions"],
            "recommended_agents": ["nutrition", "health", "meal_planning", "verification"]
        }
        """
        
        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}
                    }
                ]
            }
        ]
        
        response = await self.call_llm(messages, max_tokens=800)
        
        try:
            # Extract JSON from response
            json_start = response.find('{')
            json_end = response.rfind('}') + 1
            json_str = response[json_start:json_end]
            plan = json.loads(json_str)
            return plan
            
        except (json.JSONDecodeError, ValueError) as e:
            print(f"Warning: Failed to parse planning response: {e}")
            # Fallback plan if JSON parsing fails
            return {
                "food_items": [{"name": "unknown_food", "category": "mixed", "estimated_weight": 150, "preparation": "unknown", "confidence": 0.5}],
                "complexity": "moderate",
                "analysis_focus": ["nutrition", "health"],
                "special_considerations": [],
                "recommended_agents": ["nutrition", "health", "verification"]
            }


class NutritionAgent(BaseAgent):
    """Agent specialized in detailed nutritional analysis"""
    
    def __init__(self, api_key: str):
        super().__init__("NutritionAgent", api_key)
    
    async def analyze_nutrition(self, food_items: List[Dict], plan: Dict) -> NutritionData:
        """Perform detailed nutritional analysis based on planning agent's findings"""
        
        food_descriptions = "\n".join([
            f"- {item['name']}: {item['estimated_weight']}g, {item['preparation']}"
            for item in food_items
        ])
        
        prompt = f"""
        You are a Nutrition Agent specializing in detailed macro and micronutrient analysis.
        
        Based on the Planning Agent's analysis, calculate comprehensive nutrition data for:
        {food_descriptions}
        
        Consider:
        - Preparation method effects on nutrients
        - Portion sizes and weights
        - Food interactions and bioavailability
        - Cooking losses (vitamins, minerals)
        
        Return detailed nutrition data as JSON:
        {{
            "protein": grams,
            "carbohydrates": grams,
            "fats": grams,
            "fiber": grams,
            "calories": kcal,
            "sodium": mg,
            "sugar": grams,
            "cholesterol": mg,
            "vitamin_c": mg,
            "calcium": mg,
            "iron": mg
        }}
        
        Provide accurate estimates based on USDA nutrition database values.
        """
        
        messages = [{"role": "user", "content": prompt}]
        response = await self.call_llm(messages, max_tokens=400)
        
        try:
            json_start = response.find('{')
            json_end = response.rfind('}') + 1
            json_str = response[json_start:json_end]
            nutrition_data = json.loads(json_str)
            return NutritionData(**nutrition_data)
            
        except (json.JSONDecodeError, ValueError, TypeError) as e:
            print(f"Warning: Failed to parse nutrition response: {e}")
            # Fallback nutrition data
            return NutritionData(
                protein=20.0, carbohydrates=30.0, fats=15.0, fiber=5.0,
                calories=300, sodium=500, sugar=5.0, cholesterol=50,
                vitamin_c=10, calcium=100, iron=2.5
            )


class HealthAgent(BaseAgent):
    """Agent providing personalized health recommendations"""
    
    def __init__(self, api_key: str):
        super().__init__("HealthAgent", api_key)
    
    async def generate_recommendations(self, nutrition: NutritionData, food_items: List[Dict], 
                                     user_profile: Optional[Dict] = None) -> List[HealthRecommendation]:
        """Generate personalized health recommendations"""
        
        nutrition_summary = f"""
        Nutrition Analysis:
        - Calories: {nutrition.calories} kcal
        - Protein: {nutrition.protein}g
        - Carbohydrates: {nutrition.carbohydrates}g
        - Fats: {nutrition.fats}g
        - Fiber: {nutrition.fiber}g
        - Sodium: {nutrition.sodium}mg
        - Sugar: {nutrition.sugar}g
        """
        
        user_context = ""
        if user_profile:
            user_context = f"""
            User Profile:
            - Age: {user_profile.get('age', 'unknown')}
            - Gender: {user_profile.get('gender', 'unknown')}
            - Activity Level: {user_profile.get('activity_level', 'moderate')}
            - Health Goals: {user_profile.get('goals', ['general wellness'])}
            - Dietary Restrictions: {user_profile.get('restrictions', [])}
            """
        
        prompt = f"""
        You are a Health Agent providing personalized dietary recommendations.
        
        {nutrition_summary}
        {user_context}
        
        Analyze this meal and provide 3-5 specific health recommendations. Consider:
        - Nutritional balance and adequacy
        - Portion appropriateness
        - Timing considerations
        - Health optimization opportunities
        - Risk factors (sodium, sugar, saturated fat)
        
        Return recommendations as JSON array:
        [
            {{
                "category": "portion_control|nutrient_balance|timing|optimization",
                "message": "clear, actionable recommendation",
                "priority": "high|medium|low",
                "reasoning": "scientific basis for recommendation"
            }}
        ]
        """
        
        messages = [{"role": "user", "content": prompt}]
        response = await self.call_llm(messages, max_tokens=600)
        
        try:
            json_start = response.find('[')
            json_end = response.rfind(']') + 1
            json_str = response[json_start:json_end]
            recommendations_data = json.loads(json_str)
            return [HealthRecommendation(**rec) for rec in recommendations_data]
            
        except (json.JSONDecodeError, ValueError, TypeError) as e:
            print(f"Warning: Failed to parse health recommendations: {e}")
            # Fallback recommendations
            return [
                HealthRecommendation(
                    category="nutrient_balance",
                    message="Consider adding more vegetables to increase fiber and micronutrients.",
                    priority="medium",
                    reasoning="Current fiber content could be higher for optimal digestive health."
                )
            ]


class MealPlanningAgent(BaseAgent):
    """Agent for meal planning and food pairing suggestions"""
    
    def __init__(self, api_key: str):
        super().__init__("MealPlanningAgent", api_key)
    
    async def suggest_complementary_foods(self, nutrition: NutritionData, 
                                        food_items: List[Dict]) -> List[MealSuggestion]:
        """Suggest complementary foods to complete the meal"""
        
        current_foods = [item['name'] for item in food_items]
        
        prompt = f"""
        You are a Meal Planning Agent. Analyze the current meal and suggest complementary foods.
        
        Current meal includes: {', '.join(current_foods)}
        
        Nutritional profile:
        - Protein: {nutrition.protein}g
        - Carbohydrates: {nutrition.carbohydrates}g
        - Fats: {nutrition.fats}g
        - Fiber: {nutrition.fiber}g
        - Vitamin C: {nutrition.vitamin_c}mg
        - Calcium: {nutrition.calcium}mg
        - Iron: {nutrition.iron}mg
        
        Suggest 3-4 complementary foods that would:
        1. Balance the nutritional profile
        2. Enhance nutrient absorption
        3. Provide missing nutrients
        4. Create a well-rounded meal
        
        Return suggestions as JSON:
        [
            {{
                "food_name": "specific food item",
                "category": "vegetable|fruit|grain|protein|dairy|fat",
                "reason": "why this food complements the meal",
                "nutritional_benefit": "specific nutrient benefits"
            }}
        ]
        """
        
        messages = [{"role": "user", "content": prompt}]
        response = await self.call_llm(messages, max_tokens=500)
        
        try:
            json_start = response.find('[')
            json_end = response.rfind(']') + 1
            json_str = response[json_start:json_end]
            suggestions_data = json.loads(json_str)
            return [MealSuggestion(**suggestion) for suggestion in suggestions_data]
            
        except (json.JSONDecodeError, ValueError, TypeError) as e:
            print(f"Warning: Failed to parse meal suggestions: {e}")
            # Fallback suggestions
            return [
                MealSuggestion(
                    food_name="Mixed green salad",
                    category="vegetable",
                    reason="Adds fiber and micronutrients",
                    nutritional_benefit="Vitamins A, C, K and folate"
                )
            ]


class VerificationAgent(BaseAgent):
    """Agent for verifying and validating analysis results"""
    
    def __init__(self, api_key: str):
        super().__init__("VerificationAgent", api_key)
    
    async def verify_analysis(self, result: AnalysisResult) -> Dict[str, Any]:
        """Verify the consistency and accuracy of the complete analysis"""
        
        # Check nutritional consistency
        nutrition_check = self._verify_nutrition_values(result.nutrition)
        
        # Check recommendation relevance
        recommendation_check = self._verify_recommendations(result.health_recommendations, result.nutrition)
        
        # Calculate overall confidence
        confidence_factors = [
            nutrition_check['confidence'],
            recommendation_check['confidence'],
            result.confidence_score
        ]
        
        overall_confidence = sum(confidence_factors) / len(confidence_factors)
        
        # Generate verification summary
        verification_summary = f"""
        Verification Results:
        - Nutrition Data: {nutrition_check['status']}
        - Recommendations: {recommendation_check['status']}
        - Overall Confidence: {overall_confidence:.2f}
        
        Issues Found: {nutrition_check.get('issues', []) + recommendation_check.get('issues', [])}
        """
        
        return {
            'verified': overall_confidence > 0.7,
            'confidence': overall_confidence,
            'summary': verification_summary,
            'issues': nutrition_check.get('issues', []) + recommendation_check.get('issues', []),
            'recommendations_for_improvement': self._suggest_improvements(result)
        }
    
    def _verify_nutrition_values(self, nutrition: NutritionData) -> Dict[str, Any]:
        """Verify nutrition values are reasonable"""
        issues = []
        
        # Check for impossible values
        if nutrition.protein < 0 or nutrition.carbohydrates < 0 or nutrition.fats < 0:
            issues.append("Negative macronutrient values detected")
        
        # Check calorie calculation
        calculated_calories = (nutrition.protein * 4) + (nutrition.carbohydrates * 4) + (nutrition.fats * 9)
        if abs(nutrition.calories - calculated_calories) > 50:
            issues.append(f"Calorie calculation mismatch: {nutrition.calories} vs {calculated_calories}")
        
        # Check extreme values
        if nutrition.sodium > 2000:  # mg
            issues.append("Very high sodium content detected")
        
        confidence = 0.9 if not issues else 0.6
        status = "PASS" if not issues else "WARNINGS"
        
        return {'confidence': confidence, 'status': status, 'issues': issues}
    
    def _verify_recommendations(self, recommendations: List[HealthRecommendation], 
                              nutrition: NutritionData) -> Dict[str, Any]:
        """Verify recommendations are relevant to the nutrition data"""
        issues = []
        
        if not recommendations:
            issues.append("No health recommendations provided")
        
        # Check recommendation relevance
        high_sodium = nutrition.sodium > 800
        low_fiber = nutrition.fiber < 5
        
        sodium_addressed = any('sodium' in rec.message.lower() for rec in recommendations)
        fiber_addressed = any('fiber' in rec.message.lower() for rec in recommendations)
        
        if high_sodium and not sodium_addressed:
            issues.append("High sodium not addressed in recommendations")
        
        if low_fiber and not fiber_addressed:
            issues.append("Low fiber not addressed in recommendations")
        
        confidence = 0.8 if not issues else 0.5
        status = "PASS" if not issues else "WARNINGS"
        
        return {'confidence': confidence, 'status': status, 'issues': issues}
    
    def _suggest_improvements(self, result: AnalysisResult) -> List[str]:
        """Suggest improvements for future analyses"""
        suggestions = []
        
        if result.confidence_score < 0.8:
            suggestions.append("Consider requesting clearer food images for better identification")
        
        if len(result.health_recommendations) < 3:
            suggestions.append("Generate more comprehensive health recommendations")
        
        if not result.meal_suggestions:
            suggestions.append("Include meal planning suggestions for complete nutrition")
        
        return suggestions


class AgenticWorkflowOrchestrator:
    """Orchestrates the multi-agent food analysis workflow"""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.agents = {
            'planning': PlanningAgent(api_key),
            'nutrition': NutritionAgent(api_key),
            'health': HealthAgent(api_key),
            'meal_planning': MealPlanningAgent(api_key),
            'verification': VerificationAgent(api_key)
        }
        self.coordination_log = []
    
    async def analyze_food_image(self, image_base64: str, user_profile: Optional[Dict] = None) -> AnalysisResult:
        """Execute the complete agentic workflow for food analysis"""
        
        self.coordination_log = []
        start_time = datetime.now()
        
        try:
            # Step 1: Planning Agent analyzes image and creates strategy
            self._log("Planning Agent: Analyzing image and creating analysis strategy")
            plan = await self.agents['planning'].analyze_image_and_plan(image_base64)
            
            food_items = [FoodItem(
                name=item['name'],
                category=item['category'],
                portion_size=f"{item['estimated_weight']}g",
                confidence=item['confidence'],
                preparation_method=item['preparation'],
                estimated_weight=item['estimated_weight']
            ) for item in plan['food_items']]
            
            # Step 2: Nutrition Agent performs detailed nutritional analysis
            self._log("Nutrition Agent: Calculating comprehensive nutrition data")
            nutrition = await self.agents['nutrition'].analyze_nutrition(plan['food_items'], plan)
            
            # Step 3: Health Agent generates personalized recommendations
            self._log("Health Agent: Generating personalized health recommendations")
            health_recommendations = await self.agents['health'].generate_recommendations(
                nutrition, plan['food_items'], user_profile
            )
            
            # Step 4: Meal Planning Agent suggests complementary foods
            self._log("Meal Planning Agent: Suggesting complementary foods")
            meal_suggestions = await self.agents['meal_planning'].suggest_complementary_foods(
                nutrition, plan['food_items']
            )
            
            # Calculate overall confidence
            confidence_scores = [item.confidence for item in food_items]
            overall_confidence = sum(confidence_scores) / len(confidence_scores) if confidence_scores else 0.5
            
            # Create preliminary result
            preliminary_result = AnalysisResult(
                food_items=food_items,
                nutrition=nutrition,
                health_recommendations=health_recommendations,
                meal_suggestions=meal_suggestions,
                confidence_score=overall_confidence,
                analysis_timestamp=start_time,
                agent_coordination_log=self.coordination_log.copy()
            )
            
            # Step 5: Verification Agent validates the complete analysis
            self._log("Verification Agent: Validating analysis results")
            verification = await self.agents['verification'].verify_analysis(preliminary_result)
            
            # Update confidence based on verification
            final_confidence = (overall_confidence + verification['confidence']) / 2
            
            self._log(f"Analysis completed with confidence: {final_confidence:.2f}")
            
            # Return final result with verification info
            final_result = AnalysisResult(
                food_items=food_items,
                nutrition=nutrition,
                health_recommendations=health_recommendations,
                meal_suggestions=meal_suggestions,
                confidence_score=final_confidence,
                analysis_timestamp=start_time,
                agent_coordination_log=self.coordination_log
            )
            
            return final_result
            
        except Exception as e:
            self._log(f"Error in workflow: {str(e)}")
            raise
    
    def _log(self, message: str):
        """Add message to coordination log"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        log_entry = f"[{timestamp}] {message}"
        self.coordination_log.append(log_entry)
        print(log_entry)  # Also print for immediate feedback


def load_image_as_base64(image_path: str) -> str:
    """Load an image file and convert it to base64"""
    try:
        with open(image_path, 'rb') as img_file:
            img_data = img_file.read()
            
        # Optimize image size if it's too large
        img = Image.open(io.BytesIO(img_data))
        if img.width > 1024 or img.height > 1024:
            img.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
            
            # Convert back to bytes
            img_buffer = io.BytesIO()
            img.save(img_buffer, format='JPEG', quality=85)
            img_data = img_buffer.getvalue()
        
        return base64.b64encode(img_data).decode('utf-8')
        
    except Exception as e:
        raise Exception(f"Failed to load image {image_path}: {str(e)}")


def display_analysis_result(result: AnalysisResult):
    """Display the analysis result in a formatted way"""
    
    print("=" * 60)
    print("🤖 AGENTIC FOOD ANALYSIS RESULTS")
    print("=" * 60)
    
    print(f"📊 **Analysis Confidence:** {result.confidence_score:.1%}")
    print(f"⏰ **Analysis Time:** {result.analysis_timestamp.strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    print("🍽️ **Identified Foods:**")
    for item in result.food_items:
        print(f"   • {item.name} ({item.portion_size}) - {item.confidence:.1%} confidence")
    
    print("\n📈 **Nutrition Analysis:**")
    print(f"   • Calories: {result.nutrition.calories} kcal")
    print(f"   • Protein: {result.nutrition.protein}g")
    print(f"   • Carbohydrates: {result.nutrition.carbohydrates}g")
    print(f"   • Fats: {result.nutrition.fats}g")
    print(f"   • Fiber: {result.nutrition.fiber}g")
    print(f"   • Sodium: {result.nutrition.sodium}mg")
    print(f"   • Sugar: {result.nutrition.sugar}g")
    print(f"   • Vitamin C: {result.nutrition.vitamin_c}mg")
    print(f"   • Calcium: {result.nutrition.calcium}mg")
    print(f"   • Iron: {result.nutrition.iron}mg")
    
    print("\n💡 **Health Recommendations:**")
    for rec in result.health_recommendations:
        priority_emoji = "🔴" if rec.priority == "high" else "🟡" if rec.priority == "medium" else "🟢"
        print(f"   {priority_emoji} {rec.message}")
        print(f"      Reasoning: {rec.reasoning}")
    
    print("\n🥗 **Meal Suggestions:**")
    for suggestion in result.meal_suggestions:
        print(f"   • {suggestion.food_name}: {suggestion.reason}")
        print(f"     Benefit: {suggestion.nutritional_benefit}")
    
    print("\n🤖 **Agent Coordination Log:**")
    for log_entry in result.agent_coordination_log:
        print(f"   {log_entry}")
    
    print("=" * 60)


async def main():
    """Main function to run the agentic food analysis"""
    parser = argparse.ArgumentParser(description="Agentic Food Analysis Workflow")
    parser.add_argument("--image", required=True, help="Path to food image file")
    parser.add_argument("--api-key", required=True, help="OpenAI API key")
    parser.add_argument("--user-profile", help="Path to JSON file with user profile")
    parser.add_argument("--output", help="Path to save analysis results as JSON")
    
    args = parser.parse_args()
    
    # Validate image file exists
    if not Path(args.image).exists():
        print(f"Error: Image file {args.image} not found")
        sys.exit(1)
    
    # Load user profile if provided
    user_profile = None
    if args.user_profile:
        try:
            with open(args.user_profile, 'r') as f:
                user_profile = json.load(f)
        except Exception as e:
            print(f"Warning: Failed to load user profile: {e}")
    
    try:
        # Load and convert image to base64
        print(f"📸 Loading image: {args.image}")
        image_base64 = load_image_as_base64(args.image)
        
        # Initialize workflow orchestrator
        print("🚀 Initializing agentic workflow...")
        orchestrator = AgenticWorkflowOrchestrator(args.api_key)
        
        # Run the analysis
        print("🤖 Starting multi-agent food analysis...\n")
        result = await orchestrator.analyze_food_image(image_base64, user_profile)
        
        # Display results
        display_analysis_result(result)
        
        # Save results if requested
        if args.output:
            result_dict = asdict(result)
            # Convert datetime to string for JSON serialization
            result_dict['analysis_timestamp'] = result.analysis_timestamp.isoformat()
            
            with open(args.output, 'w') as f:
                json.dump(result_dict, f, indent=2)
            print(f"\n💾 Results saved to: {args.output}")
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())